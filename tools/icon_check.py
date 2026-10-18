import os
import argparse
from PIL import Image

base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def stats(path):
    fp = path if os.path.isabs(path) else os.path.join(base, path)
    im = Image.open(fp).convert("RGBA")
    w, h = im.size
    white = Image.new("RGBA", (w, h), (255, 255, 255, 255))
    comp = Image.alpha_composite(white, im).convert("RGB")
    crop = comp.crop((w // 4, h // 4, w * 3 // 4, h * 3 // 4))
    px = list(crop.getdata())
    r = sum(x[0] for x in px) // len(px)
    g = sum(x[1] for x in px) // len(px)
    b = sum(x[2] for x in px) // len(px)
    a = sum(p[3] for p in list(im.getdata())) // (w * h)
    return (w, h), (r, g, b), a


def main():
    parser = argparse.ArgumentParser(
        description="生成済みアイコンと元画像の画素照合レポートを出力します。"
    )
    parser.add_argument(
        "-s", "--src",
        default=os.path.join("images", "bb_icon.png"),
        help="照合に使う元画像のパス（既定: images/bb_icon.png）。",
    )
    args = parser.parse_args()

    src_path = args.src if os.path.isabs(args.src) else os.path.join(base, args.src)
    if not os.path.exists(src_path):
        raise SystemExit("元画像が見つかりません: %s" % src_path)

    lines = []
    src_dim, src_avg, src_a = stats(src_path)
    lines.append("%s | dim=%s | avg=%s | alpha=%d" % (args.src, src_dim, src_avg, src_a))
    lines.append("-" * 50)

    paths = [
        "windows/runner/resources/app_icon.ico",
        "web/favicon.png",
        "web/icons/icon_192.png",
        "web/icons/Icon-192.png",
        "web/icons/Icon-512.png",
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    ]

    for p in paths:
        fp = os.path.join(base, p)
        if not os.path.exists(fp):
            lines.append("%s MISSING" % p)
            continue
        dim, avg, a = stats(fp)
        verdict = "MATCH" if max(
            abs(avg[0] - src_avg[0]),
            abs(avg[1] - src_avg[1]),
            abs(avg[2] - src_avg[2]),
        ) < 24 else "DIFF"
        lines.append("%s | dim=%s | avg=%s | alpha=%d | %s" % (p, dim, avg, a, verdict))

    out = os.path.join(base, "tools", "icon_report.txt")
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print("\n".join(lines))


if __name__ == "__main__":
    main()
