# streamwatch-ui-legacy — CLAUDE.md

## What This Is
Flutter web app for StreamWatch. BLoC + GetIt state management. Deployed to S3/CloudFront.

## Stack
- Dart/Flutter web
- BLoC for state, GetIt for DI
- shared_ui package for design tokens (TmzTheme, TmzShell, TmzAppBar)
- DS-001 compliant (WO-044): no Material Colors.*, no fromSeed, no raw hex

## Key Paths
- lib/features/ — feature modules (home, podcasts, scheduler, type_control, etc.)
- lib/data/ — models, sources, data layer
- lib/themes/app_theme.dart — delegates to TmzTheme.dark()
- lib/utils/service_locator.dart — GetIt registration chain

## Build and Deploy
flutter build web --release --dart-define=API_BASE_URL=https://streamwatch.tmz.com/api
aws s3 sync build/web s3://streamwatch-frontend-dev-259270188737 --delete
aws cloudfront create-invalidation --distribution-id EE0PAJB58A75G --paths "/*"

## Hard Rules
- BLoC + GetIt only. No Riverpod, no Provider.
- All tokens from shared_ui. No local color/text definitions.
- No emojis in code, comments, commits, or UI strings.
- Soft deletes only unless explicitly approved.