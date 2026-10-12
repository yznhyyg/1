Add-Type -AssemblyName System.Drawing
$output = Join-Path $PSScriptRoot "four_lane_neon_clean.png"
$bitmap = New-Object System.Drawing.Bitmap(480, 540, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)

# 深色底板：让蓝色音符和青色边框有足够对比度。
$base = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(248, 13, 16, 29))
$graphics.FillRectangle($base, 0, 0, 480, 540)
$base.Dispose()

# 四个轨道使用轻微不同的深紫灰明度，整体仍然连贯。
$lane_a = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(24, 70, 66, 112))
$lane_b = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(24, 46, 45, 82))
$graphics.FillRectangle($lane_a, 2, 2, 116, 536)
$graphics.FillRectangle($lane_b, 122, 2, 116, 536)
$graphics.FillRectangle($lane_a, 242, 2, 116, 536)
$graphics.FillRectangle($lane_b, 362, 2, 116, 536)
$lane_a.Dispose()
$lane_b.Dispose()

# 极淡的斜向高光，避免背景完全平面化。
$shine = New-Object -TypeName System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(18, 118, 92, 198))
$graphics.FillPolygon($shine, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(0, 105)), (New-Object System.Drawing.Point(85, 0)), (New-Object System.Drawing.Point(145, 0)), (New-Object System.Drawing.Point(60, 105))))
$graphics.FillPolygon($shine, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(240, 410)), (New-Object System.Drawing.Point(325, 300)), (New-Object System.Drawing.Point(385, 300)), (New-Object System.Drawing.Point(300, 410))))
$shine.Dispose()

# 三条内部边界各画一次，避免相邻轨道出现双线。
$separator_glow = New-Object -TypeName System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(45, 61, 202, 236)), 4
$graphics.DrawLine($separator_glow, 120, 0, 120, 540)
$graphics.DrawLine($separator_glow, 240, 0, 240, 540)
$graphics.DrawLine($separator_glow, 360, 0, 360, 540)
$separator_glow.Dispose()
$separator = New-Object -TypeName System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(165, 102, 211, 239)), 1
$graphics.DrawLine($separator, 120, 0, 120, 540)
$graphics.DrawLine($separator, 240, 0, 240, 540)
$graphics.DrawLine($separator, 360, 0, 360, 540)
$separator.Dispose()

# 整体边界和上下内侧高光。
$outer_glow = New-Object -TypeName System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(52, 64, 207, 247)), 6
$graphics.DrawRectangle($outer_glow, 2, 2, 476, 536)
$outer_glow.Dispose()
$outer = New-Object -TypeName System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(220, 104, 228, 255)), 2
$graphics.DrawRectangle($outer, 3, 3, 474, 534)
$outer.Dispose()
$inner = New-Object -TypeName System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb(105, 189, 243, 255)), 1
$graphics.DrawLine($inner, 14, 18, 466, 18)
$graphics.DrawLine($inner, 14, 522, 466, 522)
$inner.Dispose()

$graphics.Dispose()
$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
