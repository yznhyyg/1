Add-Type -AssemblyName System.Drawing
$output = Join-Path $PSScriptRoot "lane_neon.png"
$bitmap = New-Object System.Drawing.Bitmap(120, 540, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)

$fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 18, 16, 30))
$graphics.FillRectangle($fill, 0, 0, 120, 540)
$fill.Dispose()

$shade = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 154, 91, 206))
$graphics.FillRectangle($shade, 0, 0, 118, 540)
$graphics.FillPolygon($shade, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(-30, 140)), (New-Object System.Drawing.Point(65, 0)), (New-Object System.Drawing.Point(104, 0)), (New-Object System.Drawing.Point(9, 140))))
$graphics.FillPolygon($shade, [System.Drawing.Point[]]@((New-Object System.Drawing.Point(-30, 330)), (New-Object System.Drawing.Point(105, 120)), (New-Object System.Drawing.Point(140, 120)), (New-Object System.Drawing.Point(5, 330))))
$shade.Dispose()

$inner = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 112, 234, 255), 1)
$graphics.DrawLine($inner, 118, 0, 118, 540)
$graphics.DrawLine($inner, 1, 1, 118, 1)
$graphics.DrawLine($inner, 1, 538, 118, 538)
$inner.Dispose()
$outer = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, 67, 223, 255), 2)
$graphics.DrawLine($outer, 119, 0, 119, 540)
$outer.Dispose()
$graphics.Dispose()
$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
