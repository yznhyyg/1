Add-Type -AssemblyName System.Drawing
$output = Join-Path $PSScriptRoot "four_lane_neon_v2.png"
$bitmap = New-Object System.Drawing.Bitmap(480, 540, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)

# 整体外框采用小切角，避免四条轨道拼接时出现重复圆角。
$frame_points = [System.Drawing.Point[]]@([System.Drawing.Point]::new(10, 0), [System.Drawing.Point]::new(470, 0), [System.Drawing.Point]::new(480, 10), [System.Drawing.Point]::new(480, 530), [System.Drawing.Point]::new(470, 540), [System.Drawing.Point]::new(10, 540), [System.Drawing.Point]::new(0, 530), [System.Drawing.Point]::new(0, 10))

$background = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(250, 12, 14, 26))
$graphics.FillPolygon($background, [System.Drawing.Point[]]$frame_points)
$background.Dispose()

# 每条轨道只做极轻的明暗分区，不抢音符的视觉焦点。
$lane_brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(16, 64, 87, 145))
$graphics.FillRectangle($lane_brush, 2, 2, 116, 536)
$graphics.FillRectangle($lane_brush, 122, 2, 116, 536)
$graphics.FillRectangle($lane_brush, 242, 2, 116, 536)
$graphics.FillRectangle($lane_brush, 362, 2, 116, 536)
$lane_brush.Dispose()

# 很淡的横向刻度，增加层次但不制造噪点。
$grid_pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(18, 145, 190, 225), 1)
$graphics.DrawLine($grid_pen, 12, 54, 468, 54)
$graphics.DrawLine($grid_pen, 12, 108, 468, 108)
$graphics.DrawLine($grid_pen, 12, 162, 468, 162)
$graphics.DrawLine($grid_pen, 12, 216, 468, 216)
$graphics.DrawLine($grid_pen, 12, 270, 468, 270)
$graphics.DrawLine($grid_pen, 12, 324, 468, 324)
$graphics.DrawLine($grid_pen, 12, 378, 468, 378)
$graphics.DrawLine($grid_pen, 12, 432, 468, 432)
$graphics.DrawLine($grid_pen, 12, 486, 468, 486)
$grid_pen.Dispose()

# 三条内部边界各只绘制一次，并带有很轻的外发光。
$glow = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(40, 36, 190, 235), 5)
$graphics.DrawLine($glow, 120, 10, 120, 530)
$graphics.DrawLine($glow, 240, 10, 240, 530)
$graphics.DrawLine($glow, 360, 10, 360, 530)
$glow.Dispose()
$separator = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(170, 92, 215, 245), 1)
$graphics.DrawLine($separator, 120, 8, 120, 532)
$graphics.DrawLine($separator, 240, 8, 240, 532)
$graphics.DrawLine($separator, 360, 8, 360, 532)
$separator.Dispose()
# 整体外框发光与内侧高光。
$outer_glow = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(55, 52, 210, 255), 6)
$graphics.DrawPolygon($outer_glow, [System.Drawing.Point[]]$frame_points)
$outer_glow.Dispose()
$outer = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(225, 99, 224, 255), 2)
$graphics.DrawPolygon($outer, [System.Drawing.Point[]]$frame_points)
$outer.Dispose()
$highlight = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 195, 247, 255), 1)
$graphics.DrawLine($highlight, 14, 18, 466, 18)
$graphics.DrawLine($highlight, 14, 522, 466, 522)
$highlight.Dispose()

$graphics.Dispose()
$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
