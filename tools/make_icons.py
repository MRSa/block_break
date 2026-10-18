import os
import argparse
from PIL import Image


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parser = argparse.ArgumentParser(
        description="images/bb_icon.png ベースの元画像から全アプリアイコンを再生成します。"
    )
    parser.add_argument(
        "-s", "--src",
        default=os.path.join("images", "bb_icon.png"),
        help="元画像のパス（既定: images/bb_icon.png）。相対パスはプロジェクトルート基準です。",
    )
    args = parser.parse_args()

    # 相対パスはプロジェクトルート基準、絶対パスはそのまま
    src_path = args.src if os.path.isabs(args.src) else os.path.join(base, args.src)
    if not os.path.exists(src_path):
        raise SystemExit("元画像が見つかりません: %s" % src_path)

    src = Image.open(src_path).convert("RGBA")
    print("source:", src_path, "size:", src.size, src.mode)

    def save(path, size):
        fp = os.path.join(base, path)
        os.makedirs(os.path.dirname(fp), exist_ok=True)
        src.resize((size, size), Image.LANCZOS).save(fp)
        print("wrote", path, size)

    # Windows .ico（マルチサイズ）
    sizes = [16, 24, 32, 48, 64, 128, 256]
    imgs = [src.resize((s, s), Image.LANCZOS) for s in sizes]
    ico = os.path.join(base, "windows", "runner", "resources", "app_icon.ico")
    os.makedirs(os.path.dirname(ico), exist_ok=True)
    imgs[-1].save(ico, format="ICO", append_images=imgs[:-1])
    print("wrote", "app_icon.ico", sizes)

    # Web favicon + icons
    save("web/favicon.png", 32)
    for n in [48, 72, 96, 144, 192, 384, 512]:
        save("web/icons/icon_%d.png" % n, n)

    # Web PWA (manifest.json / index.html が参照する Icon-*.png)
    save("web/icons/Icon-192.png", 192)
    save("web/icons/Icon-512.png", 512)
    save("web/icons/Icon-maskable-192.png", 192)
    save("web/icons/Icon-maskable-512.png", 512)

    # Android mipmap
    m = [
        ("android/app/src/main/res/mipmap-mdpi", 48),
        ("android/app/src/main/res/mipmap-hdpi", 72),
        ("android/app/src/main/res/mipmap-xhdpi", 96),
        ("android/app/src/main/res/mipmap-xxhdpi", 144),
        ("android/app/src/main/res/mipmap-xxxhdpi", 192),
    ]
    for d, s in m:
        save(os.path.join(d, "ic_launcher.png").replace("\\", "/"), s)

    print("DONE")


if __name__ == "__main__":
    main()
