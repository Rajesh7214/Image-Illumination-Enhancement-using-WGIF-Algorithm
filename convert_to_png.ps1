Add-Type -AssemblyName System.Drawing
$files = Get-ChildItem "C:\Users\rajes\.gemini\antigravity\scratch\image-illumination-enhancement-wgif\results\*.bmp", "C:\Users\rajes\.gemini\antigravity\scratch\image-illumination-enhancement-wgif\sample_images\*.bmp"
foreach ($f in $files) {
    $img = [System.Drawing.Image]::FromFile($f.FullName)
    $png = [System.IO.Path]::ChangeExtension($f.FullName, ".png")
    $img.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    Write-Host "Exported PNG: $png"
}
