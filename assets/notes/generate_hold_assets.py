from PIL import Image, ImageEnhance, ImageDraw, ImageFilter

root = r"C:\Users\yunzh\Documents\rg\assets\notes"
tap = Image.open(root + r"\note_normal.png").convert("RGBA")

# Hold 头部：沿用 Tap 的六边形轮廓，稍微压暗，让它和主体有层次但不割裂。
head = tap.resize((100, 16), Image.Resampling.LANCZOS)
head = ImageEnhance.Brightness(head).enhance(0.88)
head.save(root + r"\hold_head_new.png")

# Hold 主体：没有上下端帽，只有连续的蓝色渐变和青色侧边，可按任意长度平铺。
w, h = 100, 16
body = Image.new("RGBA", (w, h), (0, 0, 0, 0))
draw = ImageDraw.Draw(body)
for y in range(h):
    t = y / max(h - 1, 1)
    color = (18 + int(15 * t), 100 + int(55 * (1 - t)), 235 + int(15 * (1 - t)), 255)
    draw.line((5, y, 94, y), fill=color, width=1)

# 中央柔和高光，与 Tap 的亮面呼应。
highlight = Image.new("RGBA", (w, h), (0, 0, 0, 0))
hd = ImageDraw.Draw(highlight)
hd.rectangle((15, 2, 84, 5), fill=(175, 244, 255, 85))
highlight = highlight.filter(ImageFilter.GaussianBlur(1.2))
body.alpha_composite(highlight)
draw = ImageDraw.Draw(body)

# 两侧发光轨，保证长条宽度稳定、延伸后仍像同一枚 Tap。
draw.line((4, 1, 4, h - 2), fill=(116, 238, 255, 220), width=2)
draw.line((95, 1, 95, h - 2), fill=(50, 146, 255, 230), width=2)
draw.line((7, 1, 92, 1), fill=(192, 247, 255, 80), width=1)
body.save(root + r"\hold_body_new.png")
