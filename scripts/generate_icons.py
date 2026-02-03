#!/usr/bin/env python3
"""
Generate branded StreamWatch app icons.
Creates favicon, web icons, and Windows .ico file.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Output paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UI_DIR = os.path.dirname(SCRIPT_DIR)
WEB_DIR = os.path.join(UI_DIR, "web")
WINDOWS_DIR = os.path.join(UI_DIR, "windows", "runner", "resources")

# TMZ brand colors
TMZ_RED = "#E31837"  # TMZ red
TMZ_BLACK = "#1A1A1A"
WHITE = "#FFFFFF"

# Icon background - use TMZ red for brand recognition
BG_COLOR = TMZ_RED
TEXT_COLOR = WHITE


def create_streamwatch_icon(size: int) -> Image.Image:
    """Create a StreamWatch branded icon at the given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw rounded rectangle background
    margin = int(size * 0.08)
    radius = int(size * 0.18)
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=BG_COLOR
    )

    # Calculate font size - "SW" text
    font_size = int(size * 0.45)

    # Try to use a bold system font, fall back to default
    font = None
    font_names = [
        "arialbd.ttf",      # Arial Bold (Windows)
        "Arial Bold.ttf",   # Arial Bold (Mac)
        "DejaVuSans-Bold.ttf",
        "FreeSansBold.ttf",
    ]

    for font_name in font_names:
        try:
            font = ImageFont.truetype(font_name, font_size)
            break
        except (IOError, OSError):
            continue

    if font is None:
        # Use default font (will be small but functional)
        font = ImageFont.load_default()
        font_size = int(size * 0.3)

    # Draw "SW" text centered
    text = "SW"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]  # Adjust for font baseline

    draw.text((x, y), text, fill=TEXT_COLOR, font=font)

    return img


def create_maskable_icon(size: int) -> Image.Image:
    """Create a maskable icon with safe zone padding."""
    img = Image.new("RGBA", (size, size), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Maskable icons need content in the center 80% (safe zone)
    # The outer 10% on each side may be cropped
    safe_zone = int(size * 0.8)
    offset = int(size * 0.1)

    # Calculate font size for safe zone
    font_size = int(safe_zone * 0.45)

    font = None
    font_names = ["arialbd.ttf", "Arial Bold.ttf", "DejaVuSans-Bold.ttf"]

    for font_name in font_names:
        try:
            font = ImageFont.truetype(font_name, font_size)
            break
        except (IOError, OSError):
            continue

    if font is None:
        font = ImageFont.load_default()

    # Draw "SW" text centered
    text = "SW"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]

    draw.text((x, y), text, fill=TEXT_COLOR, font=font)

    return img


def main():
    print("Generating StreamWatch branded icons...")

    # Create directories if needed
    os.makedirs(os.path.join(WEB_DIR, "icons"), exist_ok=True)
    os.makedirs(WINDOWS_DIR, exist_ok=True)

    # Generate web icons
    sizes = {
        "favicon.png": 32,
        "icons/Icon-192.png": 192,
        "icons/Icon-512.png": 512,
    }

    for filename, size in sizes.items():
        icon = create_streamwatch_icon(size)
        path = os.path.join(WEB_DIR, filename)
        icon.save(path, "PNG")
        print(f"  Created {filename} ({size}x{size})")

    # Generate maskable icons
    maskable_sizes = {
        "icons/Icon-maskable-192.png": 192,
        "icons/Icon-maskable-512.png": 512,
    }

    for filename, size in maskable_sizes.items():
        icon = create_maskable_icon(size)
        path = os.path.join(WEB_DIR, filename)
        icon.save(path, "PNG")
        print(f"  Created {filename} ({size}x{size})")

    # Generate Windows .ico file (multi-resolution)
    ico_sizes = [16, 32, 48, 64, 128, 256]
    ico_images = [create_streamwatch_icon(s) for s in ico_sizes]

    ico_path = os.path.join(WINDOWS_DIR, "app_icon.ico")
    ico_images[0].save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in ico_sizes],
        append_images=ico_images[1:]
    )
    print(f"  Created app_icon.ico ({', '.join(str(s) for s in ico_sizes)})")

    print("\nDone! Icon files generated:")
    print(f"  Web:     {WEB_DIR}")
    print(f"  Windows: {WINDOWS_DIR}")
    print("\nRebuild the app to see changes.")


if __name__ == "__main__":
    main()
