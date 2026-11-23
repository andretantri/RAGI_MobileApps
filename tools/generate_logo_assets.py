#!/usr/bin/env python3
"""Pasang aset ikon aplikasi dari `tools/myin-u-staff-icons.zip`.

Aset yang dihasilkan/disalin:
- `assets/images/logo.png`                  -> banner login (tetap dari `logo.png`)
- Android launcher legacy/adaptive/round/monochrome
- Android notification small/large icon     -> dibuat dari aset zip
- iOS `AppIcon.appiconset` (semua ukuran)
- `values/notification_colors.xml`          -> warna tint notifikasi

Cara jalankan dari root project:
    python3 tools/generate_logo_assets.py
"""

from __future__ import annotations

import shutil
import tempfile
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "logo.png"
ICON_ZIP = ROOT / "tools" / "myin-u-staff-icons.zip"

ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_APPICON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

# density -> multiplier dp
DENSITIES = {
    "mdpi": 1,
    "hdpi": 1.5,
    "xhdpi": 2,
    "xxhdpi": 3,
    "xxxhdpi": 4,
}

# Biru dominan pada ikon baru (sampled dari playstore-512.png).
NOTIFICATION_COLOR = "#0B52B3"
WHITE = (255, 255, 255, 255)


def install_android(res_dir: Path, written: list[Path]) -> None:
    """Timpa launcher Android dengan aset dari zip."""
    for path in ANDROID_RES.glob("mipmap-*"):
        if path.is_dir():
            shutil.rmtree(path)

    for item in sorted(res_dir.iterdir()):
        target = ANDROID_RES / item.name
        if item.is_dir():
            shutil.copytree(item, target, dirs_exist_ok=True)
            written.extend(
                target / source.relative_to(item)
                for source in sorted(item.rglob("*"))
                if source.is_file()
            )
        else:
            shutil.copy2(item, target)
            written.append(target)


def install_ios(appiconset_dir: Path, written: list[Path]) -> None:
    """Ganti seluruh AppIcon iOS mengikuti Contents.json dari zip."""
    if IOS_APPICON.exists():
        shutil.rmtree(IOS_APPICON)
    shutil.copytree(appiconset_dir, IOS_APPICON)
    written.extend(p for p in IOS_APPICON.rglob("*") if p.is_file())


def write_notification_color(written: list[Path]) -> None:
    values = ANDROID_RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    path = values / "notification_colors.xml"
    path.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="notification_color">{NOTIFICATION_COLOR}</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )
    written.append(path)


def notification_icons(android_dir: Path, written: list[Path]) -> None:
    """Buat small icon putih-transparan & large icon dari aset zip."""
    monochrome_path = (
        android_dir / "res" / "mipmap-xxxhdpi" / "ic_launcher_monochrome.png"
    )
    large_source = android_dir / "playstore-512.png"

    monochrome = Image.open(monochrome_path).convert("RGBA")
    bbox = monochrome.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("ic_launcher_monochrome.png tidak memiliki siluet.")
    monochrome = monochrome.crop(bbox)

    large = Image.open(large_source).convert("RGB")

    for density, scale in DENSITIES.items():
        drawable = ANDROID_RES / f"drawable-{density}"
        drawable.mkdir(parents=True, exist_ok=True)

        # Small icon: siluet putih di atas kanvas transparan 24 dp.
        size = round(24 * scale)
        inner = round(size * 0.84)
        ratio = min(inner / monochrome.width, inner / monochrome.height)
        width = max(1, round(monochrome.width * ratio))
        height = max(1, round(monochrome.height * ratio))
        mask = monochrome.resize((width, height), Image.Resampling.LANCZOS)
        silhouette = Image.new("RGBA", (width, height), WHITE)
        silhouette.putalpha(mask.getchannel("A"))

        small = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        small.alpha_composite(
            silhouette, ((size - width) // 2, (size - height) // 2)
        )
        small_path = drawable / "ic_stat_logo.png"
        small.save(small_path, "PNG", optimize=True)
        written.append(small_path)

        # Large icon: versi kotak penuh dari playstore-512.png.
        large_size = round(64 * scale)
        large_path = drawable / "ic_notification_large.png"
        large.resize((large_size, large_size), Image.Resampling.LANCZOS).save(
            large_path, "PNG", optimize=True
        )
        written.append(large_path)


def main() -> None:
    for required in (SOURCE, ICON_ZIP):
        if not required.exists():
            raise FileNotFoundError(f"File sumber tidak ditemukan: {required}")

    # Logo asli disalin utuh untuk dipakai sebagai banner halaman login.
    target_logo = ROOT / "assets" / "images" / "logo.png"
    target_logo.parent.mkdir(parents=True, exist_ok=True)
    target_logo.write_bytes(SOURCE.read_bytes())

    written: list[Path] = [target_logo]

    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(ICON_ZIP) as archive:
            archive.extractall(tmp)

        bundle = Path(tmp) / "myin-u-staff-icons"
        android_dir = bundle / "android"
        ios_dir = bundle / "ios" / "AppIcon.appiconset"
        if not android_dir.is_dir() or not ios_dir.is_dir():
            raise ValueError("Struktur zip ikon tidak sesuai.")

        install_android(android_dir / "res", written)
        install_ios(ios_dir, written)
        notification_icons(android_dir, written)
        write_notification_color(written)

    files = sorted(set(written))
    print(f"Sumber ikon : {ICON_ZIP.relative_to(ROOT)}")
    print(f"Warna notif : {NOTIFICATION_COLOR}")
    print(f"Dibuat      : {len(files)} file")
    for path in files:
        print(f"  - {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
