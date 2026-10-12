Add-Type -AssemblyName System.Drawing
$output = Join-Path $PSScriptRoot "four_lane_neon.png"
$bitmap = New-Object System.Drawing.Bitmap(480, 540, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)

$outer = New-Object System.Drawing.Drawing2D.GraphicsPath
$outer.AddArc(8, 0, 20, 20, 180, 90)
$outer.AddArc(452, 0, 20, 20, 270, 90)
$outer.AddArc(452, 520, 20, 20, 0, 90)
$outer.AddArc(8, 520, 20, 20, 90, 90)
$outer.CloseFigure()
$fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(248, 18, 16, 30))
$graphics.FillPath($fill, $outer)
$fill.Dispose()

$shade = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 154, 91, 206))
$graphics.SetClip($outer)
$graphics.FillPolygon($shade, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(-80, 180)), (New-Object System.Drawing.Point(85, 0)), (New-Object System.Drawing.Point(190, 0)), (New-Object System.Drawing.Point(25, 180))))
$graphics.FillPolygon($shade, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(80, 540)), (New-Object System.Drawing.Point(260, 220)), (New-Object System.Drawing.Point(355, 220)), (New-Object System.Drawing.Point(175, 540))))
$graphics.FillPolygon($shade, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(300, 540)), (New-Object System.Drawing.Point(470, 260)), (New-Object System.Drawing.Point(540, 260)), (New-Object System.Drawing.Point(370, 540))))
$shade.Dispose()
$graphics.ResetClip()

$separator = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(175, 112, 234, 255), 2)
foreach ($x in @(120, 240, 360)) { $graphics.DrawLine($separator, $x, 8, $x, 532) }
$separator.Dispose()
$border = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(225, 67, 223, 255), 3)
$graphics.DrawPath($border, $outer)
$border.Dispose()
$detail = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(135, 185, 251, 255), 1)
$graphics.DrawLine($detail, 20, 22, 460, 22)
$graphics.DrawLine($detail, 20, 518, 460, 518)
$detail.Dispose()
$graphics.Dispose()
$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
