<#
.SYNOPSIS
Embed dreamstime-embed.ps1 + the icon/logo into "Dreamstime Metadata Tool.hta",
turning it into a single self-contained, portable file.

.DESCRIPTION
The HTA keeps three placeholder variables (PS1_B64 / LOGO_B64 / ICO_B64).
This script fills them with base64 of the real source files, so the .hta can be
copied anywhere on its own and still run (it unpacks the script + icon to
%APPDATA%\DreamstimeMetadataTool at runtime). dreamstime-embed.ps1 remains the
source of truth — re-run this script after editing it to refresh the embed.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-standalone-hta.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = if($PSScriptRoot){ $PSScriptRoot } else { (Get-Location).Path }
$hta  = Join-Path $root 'Dreamstime Metadata Tool.hta'
$ps1  = Join-Path $root 'dreamstime-embed.ps1'
$ico  = Join-Path $root 'assets\dreamstime-tool-icon.ico'
$png1k= Join-Path $root 'assets\dreamstime-tool-icon-1024.png'
$png  = Join-Path $root 'assets\dreamstime-tool-icon.png'

foreach($f in @($hta,$ps1,$ico)){
  if(-not (Test-Path -LiteralPath $f)){ throw "Required file not found: $f" }
}

function ConvertTo-B64([string]$path){
  return [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
}

function Get-SmallLogoB64([string]$path, [int]$size){
  Add-Type -AssemblyName System.Drawing
  $img = [System.Drawing.Image]::FromFile($path)
  try{
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    try{
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.DrawImage($img, 0, 0, $size, $size)
      $g.Dispose()
      $ms = New-Object System.IO.MemoryStream
      $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
      return [Convert]::ToBase64String($ms.ToArray())
    } finally { $bmp.Dispose() }
  } finally { $img.Dispose() }
}

$ps1B64 = ConvertTo-B64 $ps1
$icoB64 = ConvertTo-B64 $ico
$logoB64 =
  if(Test-Path -LiteralPath $png1k){ Get-SmallLogoB64 $png1k 128 }
  elseif(Test-Path -LiteralPath $png){ Get-SmallLogoB64 $png 128 }
  else { '' }

# Base64 alphabet is [A-Za-z0-9+/=] only — no $ or \ — so it is safe to use
# directly as a .NET regex replacement string.
$text = [System.IO.File]::ReadAllText($hta, [System.Text.Encoding]::UTF8)
$text = [regex]::Replace($text, 'var PS1_B64\s*=\s*"[^"]*";',  ('var PS1_B64  = "'  + $ps1B64  + '";'))
$text = [regex]::Replace($text, 'var LOGO_B64\s*=\s*"[^"]*";', ('var LOGO_B64 = "' + $logoB64 + '";'))
$text = [regex]::Replace($text, 'var ICO_B64\s*=\s*"[^"]*";',  ('var ICO_B64  = "'  + $icoB64  + '";'))

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($hta, $text, $utf8NoBom)

Write-Host "Embedded into: $hta"
Write-Host ("  PS1_B64  = {0,8} chars" -f $ps1B64.Length)
Write-Host ("  LOGO_B64 = {0,8} chars" -f $logoB64.Length)
Write-Host ("  ICO_B64  = {0,8} chars" -f $icoB64.Length)
Write-Host "Done. The .hta is now a single self-contained file."
