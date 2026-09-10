"""Sinh icon app: HẠT CÀ PHÊ + ĐỒNG XU (thiết kế gốc bằng code, không dùng ảnh stock).

Phong cách FLAT: nền trắng, hạt nâu đặc có rãnh trắng, đồng xu vàng đặc có ký hiệu $ trắng.
Không viền, không đổ bóng, không gradient.

Chạy: python tool/make_icon.py
Kết quả: assets/icon/app_icon.png            (có nền trắng: Android legacy + iOS)
         assets/icon/app_icon_foreground.png (nền trong suốt: adaptive icon)
         assets/icon/app_icon_bg.png         (nền trắng cho adaptive icon)
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFont

SIZE = 1024
SS = 4  # supersampling cho nét mượt
S = SIZE * SS

BG = (255, 255, 255, 255)         # nền trắng
BEAN = (74, 46, 35, 255)          # nâu cà phê đặc
CREASE = (255, 255, 255, 255)     # rãnh hạt màu trắng
COIN = (255, 199, 20, 255)        # vàng đồng xu đặc
COIN_TEXT = (255, 255, 255, 255)  # ký hiệu tiền màu trắng

# Ký hiệu trên đồng xu: "$" (đô la) hoặc "\u20ab" (đồng Việt Nam).
SYMBOL = "$"

BEAN_SCALE = 0.70   # chiều dài hạt so với cạnh khung
BEAN_RATIO = 0.78   # bề ngang / chiều dài hạt (to = mập)
BEAN_ANGLE = -38.0  # độ nghiêng của hạt (âm = ngả phải)
BEAN_CX, BEAN_CY = 0.44, 0.42   # tâm hạt
CREASE_W = 0.075    # bề rộng rãnh hạt (so với bề ngang hạt)
CREASE_AMP = 0.06   # độ cong rãnh chữ S (nhỏ = cong nhẹ, gần thẳng)
CREASE_INSET = 0.07 # rãnh lùi vào trong, không chạm 2 đầu hạt (so với chiều dài hạt)

COIN_RATIO = 0.46   # đường kính đồng xu so với cạnh khung
COIN_CX, COIN_CY = 0.70, 0.70   # tâm đồng xu

FONT_CANDIDATES = (
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\seguisb.ttf",
    r"C:\Windows\Fonts\arial.ttf",
)


def load_font(px: int):
    """Nạp font đậm có ký hiệu tiền; fallback font mặc định."""
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, px)
            except OSError:
                continue
    return ImageFont.load_default()


def make_bg(size: int) -> Image.Image:
    """Nền trắng đặc."""
    return Image.new("RGBA", (size, size), BG)


def crease_outline(short_axis: int, long_axis: int, steps: int = 400) -> list:
    """Đa giác rãnh hạt: đường tâm chữ S cong RẤT NHẸ + 2 mép song song + 2 đầu bo tròn.

    Độ cong nhỏ (CREASE_AMP) + hai đầu lùi vào trong (CREASE_INSET) để hạt không
    bị đọc thành "quả bóng bầu dục" (oval + đường lằn chạy hết 2 đầu).
    Vẽ rãnh bằng đa giác (thay vì nét line) để mép rãnh mượt, không bị răng cưa.
    """
    cx = short_axis / 2
    amp = short_axis * CREASE_AMP
    half = max(1.0, short_axis * CREASE_W / 2)
    y0 = long_axis * CREASE_INSET
    y1 = long_axis - y0

    pts = []
    for i in range(steps + 1):
        t = i / steps
        # sin(pi*t) làm hai đầu rãnh thu về giữa hạt -> cong nhẹ, tự nhiên
        wave = math.sin(math.pi * t) * math.sin(2 * math.pi * t)
        pts.append((cx + amp * wave, y0 + t * (y1 - y0)))

    n = len(pts)
    normals = []
    tangents = []
    for i in range(n):
        x0, y0 = pts[max(0, i - 1)]
        x1, y1 = pts[min(n - 1, i + 1)]
        dx, dy = x1 - x0, y1 - y0
        d = math.hypot(dx, dy) or 1.0
        tangents.append((dx / d, dy / d))
        normals.append((-dy / d, dx / d))

    left = [
        (pts[i][0] + normals[i][0] * half, pts[i][1] + normals[i][1] * half)
        for i in range(n)
    ]
    right = [
        (pts[i][0] - normals[i][0] * half, pts[i][1] - normals[i][1] * half)
        for i in range(n)
    ]

    caps = 32
    end_cap = [
        (
            pts[-1][0] + half * (math.cos(a) * normals[-1][0] + math.sin(a) * tangents[-1][0]),
            pts[-1][1] + half * (math.cos(a) * normals[-1][1] + math.sin(a) * tangents[-1][1]),
        )
        for a in (math.pi * i / caps for i in range(caps + 1))
    ]
    start_cap = [
        (
            pts[0][0] - half * (math.cos(a) * normals[0][0] + math.sin(a) * tangents[0][0]),
            pts[0][1] - half * (math.cos(a) * normals[0][1] + math.sin(a) * tangents[0][1]),
        )
        for a in (math.pi * i / caps for i in range(caps + 1))
    ]
    return left + end_cap + right[::-1] + start_cap


def draw_bean(scale: float, rotate: float = BEAN_ANGLE) -> Image.Image:
    """Vẽ 1 hạt cà phê phẳng (nâu đặc + rãnh trắng) -> ảnh S x S trong suốt."""
    long_axis = int(S * scale)
    short_axis = int(long_axis * BEAN_RATIO)

    body = Image.new("RGBA", (short_axis, long_axis), (0, 0, 0, 0))
    ImageDraw.Draw(body).ellipse((0, 0, short_axis - 1, long_axis - 1), fill=BEAN)

    # Mặt nạ = lòng hạt, để rãnh không tràn ra ngoài mép hạt
    mask = Image.new("L", body.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, short_axis - 1, long_axis - 1), fill=255)

    # Rãnh hạt: đường cong chữ S nhẹ chạy dọc trục dài, màu trắng
    crease = Image.new("RGBA", body.size, (0, 0, 0, 0))
    ImageDraw.Draw(crease).polygon(crease_outline(short_axis, long_axis), fill=CREASE)
    crease.putalpha(ImageChops.multiply(crease.getchannel("A"), mask))
    body.alpha_composite(crease)

    body = body.rotate(rotate, expand=True, resample=Image.BICUBIC)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    canvas.alpha_composite(body, ((S - body.width) // 2, (S - body.height) // 2))
    return canvas


def draw_coin(size: int, symbol: str) -> Image.Image:
    """Vẽ 1 đồng xu vàng phẳng + ký hiệu tiền trắng -> ảnh size x size trong suốt."""
    coin = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(coin)
    r = size - 1
    d.ellipse((0, 0, r, r), fill=COIN)
    d.text(
        (size / 2, size / 2 - size * 0.015),
        symbol,
        font=load_font(int(size * 0.62)),
        fill=COIN_TEXT,
        anchor="mm",
    )
    return coin


def make_composition(symbol: str = SYMBOL) -> Image.Image:
    """Hạt cà phê + đồng xu (không nền), lấp gần kín khung."""
    bean = draw_bean(BEAN_SCALE)
    coin = draw_coin(int(S * COIN_RATIO), symbol)

    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    canvas.alpha_composite(
        bean, (int(S * BEAN_CX - bean.width / 2), int(S * BEAN_CY - bean.height / 2))
    )
    canvas.alpha_composite(
        coin, (int(S * COIN_CX - coin.width / 2), int(S * COIN_CY - coin.height / 2))
    )
    return canvas


def scaled(img: Image.Image, factor: float) -> Image.Image:
    """Thu nhỏ ảnh vuông S x S theo hệ số factor."""
    size = max(1, int(S * factor))
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    out_dir = os.path.join("assets", "icon")
    os.makedirs(out_dir, exist_ok=True)

    art = make_composition()

    # 1) Icon có nền trắng (Android legacy + iOS): nội dung lấp kín khung
    inner = scaled(art, 0.98)
    icon = make_bg(S)
    icon.alpha_composite(inner, ((S - inner.width) // 2, (S - inner.height) // 2))
    icon.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS).save(
        os.path.join(out_dir, "app_icon.png")
    )

    # 2) Foreground trong suốt (Android 8+): lấp kín vùng hiển thị của adaptive icon
    inner = scaled(art, 0.80)
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    fg.alpha_composite(inner, ((S - inner.width) // 2, (S - inner.height) // 2))
    fg.resize((SIZE, SIZE), Image.LANCZOS).save(
        os.path.join(out_dir, "app_icon_foreground.png")
    )

    # 3) Nền trắng cho adaptive icon
    make_bg(SIZE).convert("RGB").save(os.path.join(out_dir, "app_icon_bg.png"))

    print("Da tao icon tai", os.path.abspath(out_dir))


if __name__ == "__main__":
    main()
