from PIL import Image, ImageDraw, ImageFilter

W, H = 480, 540
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# 深色玻璃底，给蓝色音符留出清晰对比。
for y in range(H):
    t = y / (H - 1)
    color = (12 + int(5 * t), 14 + int(5 * t), 28 + int(12 * t), 248)
    draw.line((0, y, W, y), fill=color)

# 四个轨道的轻微明暗交替，不使用抢眼的大斜纹。
for lane in range(4):
    x0 = lane * 120 + 2
    x1 = lane * 120 + 118
    fill = (35, 39, 74, 38) if lane % 2 == 0 else (78, 47, 110, 26)
    draw.rectangle((x0, 2, x1, H - 3), fill=fill)

# 极淡的横向节拍刻度。
for y in range(54, H, 54):
    draw.line((12, y, W - 12, y), fill=(123, 173, 220, 16), width=1)

# 内部边界的柔和光晕和细线。
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
for x in (120, 240, 360):
    glow_draw.line((x, 8, x, H - 8), fill=(53, 197, 255, 75), width=5)
glow = glow.filter(ImageFilter.GaussianBlur(4))
img.alpha_composite(glow)
draw = ImageDraw.Draw(img)
for x in (120, 240, 360):
    draw.line((x, 8, x, H - 8), fill=(105, 221, 247, 180), width=1)

# 整体边框、内侧高光和轻微圆角。
border = Image.new("RGBA", (W, H), (0, 0, 0, 0))
border_draw = ImageDraw.Draw(border)
border_draw.rounded_rectangle((2, 2, W - 3, H - 3), radius=10, outline=(46, 194, 255, 75), width=7)
border = border.filter(ImageFilter.GaussianBlur(4))
img.alpha_composite(border)
draw = ImageDraw.Draw(img)
draw.rounded_rectangle((3, 3, W - 4, H - 4), radius=9, outline=(107, 231, 255, 225), width=2)
draw.line((16, 18, W - 16, 18), fill=(196, 249, 255, 110), width=1)
draw.line((16, H - 18, W - 16, H - 18), fill=(105, 205, 255, 80), width=1)

img.save("C:/Users/yunzh/Documents/rg/assets/lanes/four_lane_neon_clean.png")
