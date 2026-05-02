from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "images" / "app_logo.png"


def _cropped_logo() -> Image.Image:
    logo = Image.open(SOURCE).convert("RGBA")
    bbox = logo.getbbox()
    if bbox is None:
        raise RuntimeError(f"No visible pixels found in {SOURCE}")
    return logo.crop(bbox)


def _paste_centered(
    canvas: Image.Image,
    logo: Image.Image,
    *,
    target_width: int,
) -> Image.Image:
    scale = target_width / logo.width
    target_height = round(logo.height * scale)
    resized = logo.resize((target_width, target_height), Image.LANCZOS)
    offset = (
        (canvas.width - resized.width) // 2,
        (canvas.height - resized.height) // 2,
    )
    canvas.alpha_composite(resized, offset)
    return canvas


def _save_square_logo(path: Path, size: int, logo_width: int, background) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGBA", (size, size), background)
    _paste_centered(canvas, _cropped_logo(), target_width=logo_width)
    canvas.save(path)


def main() -> None:
    images_dir = ROOT / "assets" / "images"

    # White legacy icon source: safe inside rounded launcher masks.
    _save_square_logo(
        images_dir / "app_icon_source.png",
        size=1024,
        logo_width=720,
        background=(255, 255, 255, 255),
    )

    # Transparent adaptive foreground: Android supplies the white background.
    _save_square_logo(
        images_dir / "app_icon_foreground.png",
        size=1024,
        logo_width=700,
        background=(255, 255, 255, 0),
    )

    # Flutter splash logo: transparent, centered, and large enough for clarity.
    _save_square_logo(
        images_dir / "splash_logo.png",
        size=512,
        logo_width=400,
        background=(255, 255, 255, 0),
    )

    # Native Android splash bitmap resources targeting a consistent 200dp mark.
    densities = {
        "mdpi": 200,
        "hdpi": 300,
        "xhdpi": 400,
        "xxhdpi": 600,
        "xxxhdpi": 800,
    }
    for density, size in densities.items():
        _save_square_logo(
            ROOT
            / "android"
            / "app"
            / "src"
            / "main"
            / "res"
            / f"drawable-{density}"
            / "splash_logo.png",
            size=size,
            logo_width=round(size * 0.78),
            background=(255, 255, 255, 0),
        )


if __name__ == "__main__":
    main()
