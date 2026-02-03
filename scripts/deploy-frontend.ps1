<#
.SYNOPSIS
    Deploy StreamWatch Flutter frontend to S3 + CloudFront

.DESCRIPTION
    Builds the Flutter web app (optional), deploys/updates the CloudFormation stack
    for S3+CloudFront hosting, syncs assets, and invalidates the CloudFront cache.

.PARAMETER StackName
    CloudFormation stack name. Default: streamwatch-frontend-dev

.PARAMETER Region
    AWS region. Default: us-east-1

.PARAMETER Environment
    Environment tag (dev, staging, prod). Default: dev

.PARAMETER ApiBaseUrl
    API base URL baked into the Flutter build.
    Default: https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com

.PARAMETER SkipBuild
    Skip Flutter build step (use existing build/web)

.EXAMPLE
    .\deploy-frontend.ps1

.EXAMPLE
    .\deploy-frontend.ps1 -StackName streamwatch-frontend-prod -Environment prod

.EXAMPLE
    .\deploy-frontend.ps1 -SkipBuild
#>

param(
    [string]$StackName = "streamwatch-frontend-dev",
    [string]$Region = "us-east-1",
    [string]$Environment = "dev",
    [string]$ApiBaseUrl = "https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# Paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UIRoot = Split-Path -Parent $ScriptDir
$InfraDir = Join-Path $UIRoot "infra"
$BuildDir = Join-Path $UIRoot "build\web"
$TemplatePath = Join-Path $InfraDir "frontend-hosting.yaml"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " StreamWatch Frontend Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stack:       $StackName"
Write-Host "Region:      $Region"
Write-Host "Environment: $Environment"
Write-Host "API URL:     $ApiBaseUrl"
Write-Host "Skip Build:  $SkipBuild"
Write-Host ""

# Step 1: Verify AWS credentials
Write-Host "[1/7] Verifying AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --region $Region 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI not configured or credentials invalid: $identity"
    }
    $identityJson = $identity | ConvertFrom-Json
    Write-Host "  Account: $($identityJson.Account)" -ForegroundColor Green
    Write-Host "  User:    $($identityJson.Arn)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: AWS credentials check failed." -ForegroundColor Red
    Write-Host "  Ensure AWS CLI is installed and configured." -ForegroundColor Red
    Write-Host "  Run: aws configure" -ForegroundColor Red
    exit 1
}

# Step 2: Build Flutter web (unless skipped)
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "[2/7] Building Flutter web app..." -ForegroundColor Yellow
    Write-Host "  API_BASE_URL = $ApiBaseUrl"

    Push-Location $UIRoot
    try {
        flutter build web --dart-define="API_BASE_URL=$ApiBaseUrl"
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter build failed"
        }
        Write-Host "  Build complete: $BuildDir" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host ""
    Write-Host "[2/7] Skipping Flutter build (using existing build/web)" -ForegroundColor Yellow

    if (-not (Test-Path $BuildDir)) {
        Write-Host "ERROR: Build directory not found: $BuildDir" -ForegroundColor Red
        Write-Host "  Run without -SkipBuild to create it." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Using: $BuildDir" -ForegroundColor Green
}

# Step 3: Deploy/update CloudFormation stack
Write-Host ""
Write-Host "[3/7] Deploying CloudFormation stack..." -ForegroundColor Yellow

if (-not (Test-Path $TemplatePath)) {
    Write-Host "ERROR: Template not found: $TemplatePath" -ForegroundColor Red
    exit 1
}

aws cloudformation deploy `
    --template-file $TemplatePath `
    --stack-name $StackName `
    --region $Region `
    --parameter-overrides "Environment=$Environment" `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFormation deployment failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Stack deployed/updated successfully." -ForegroundColor Green

# Step 4: Get stack outputs
Write-Host ""
Write-Host "[4/7] Retrieving stack outputs..." -ForegroundColor Yellow

$outputsJson = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].Outputs" `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get stack outputs." -ForegroundColor Red
    exit 1
}

$outputs = $outputsJson | ConvertFrom-Json

$BucketName = ($outputs | Where-Object { $_.OutputKey -eq "FrontendBucketName" }).OutputValue
$DistributionId = ($outputs | Where-Object { $_.OutputKey -eq "CloudFrontDistributionId" }).OutputValue
$CloudFrontDomain = ($outputs | Where-Object { $_.OutputKey -eq "CloudFrontDomainName" }).OutputValue
$FrontendURL = ($outputs | Where-Object { $_.OutputKey -eq "FrontendURL" }).OutputValue

Write-Host "  Bucket:       $BucketName" -ForegroundColor Green
Write-Host "  Distribution: $DistributionId" -ForegroundColor Green
Write-Host "  Domain:       $CloudFrontDomain" -ForegroundColor Green

# Step 5: Sync assets to S3
Write-Host ""
Write-Host "[5/7] Syncing assets to S3..." -ForegroundColor Yellow

aws s3 sync $BuildDir "s3://$BucketName" --delete --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 sync failed." -ForegroundColor Red
    exit 1
}
Write-Host "  Assets synced successfully." -ForegroundColor Green

# Step 6: Set cache headers for non-hashed files
Write-Host ""
Write-Host "[6/7] Setting cache headers for index.html..." -ForegroundColor Yellow

# index.html and flutter_service_worker.js should not be cached
$NoCacheFiles = @("index.html", "flutter_service_worker.js", "flutter_bootstrap.js", "version.json")

foreach ($file in $NoCacheFiles) {
    $localPath = Join-Path $BuildDir $file
    if (Test-Path $localPath) {
        aws s3 cp $localPath "s3://$BucketName/$file" `
            --cache-control "no-cache, no-store, must-revalidate" `
            --content-type $(if ($file -like "*.html") { "text/html" } elseif ($file -like "*.js") { "application/javascript" } else { "application/json" }) `
            --region $Region 2>&1 | Out-Null
        Write-Host "  $file -> no-cache" -ForegroundColor Green
    }
}

# Step 7: Invalidate CloudFront cache
Write-Host ""
Write-Host "[7/7] Invalidating CloudFront cache..." -ForegroundColor Yellow

$invalidationResult = aws cloudfront create-invalidation `
    --distribution-id $DistributionId `
    --paths "/*" `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Cache invalidation failed (non-critical)." -ForegroundColor Yellow
}
else {
    $invalidation = $invalidationResult | ConvertFrom-Json
    Write-Host "  Invalidation ID: $($invalidation.Invalidation.Id)" -ForegroundColor Green
}

# Done
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend URL: $FrontendURL" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: CloudFront propagation may take 1-5 minutes." -ForegroundColor Yellow
Write-Host "      API_BASE_URL is baked at build time." -ForegroundColor Yellow
Write-Host "      Re-run without -SkipBuild to change it." -ForegroundColor Yellow
Write-Host ""
