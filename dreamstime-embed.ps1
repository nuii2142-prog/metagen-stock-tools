<# 
.SYNOPSIS
Embed Dreamstime metadata from a MetaGen Dreamstime CSV into copied image files.

.DESCRIPTION
Reads the Dreamstime CSV exported by MetaGen, copies matching images to an output
folder, embeds IPTC/XMP/EXIF metadata with ExifTool, then writes a verification
report. Source images are never modified.

.EXAMPLE
.\dreamstime-embed.ps1 -Csv ".\MetaGen_Dreamstime_2026-06-09.csv" -ImagesDir ".\images" -OutDir ".\dreamstime-ready" -AiMode ai -AiModel "Adobe Firefly"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$Csv,

  [Parameter(Mandatory=$true)]
  [string]$ImagesDir,

  [string]$OutDir,

  [ValidateSet('ai','nonai')]
  [string]$AiMode = 'ai',

  [string]$AiModel = '',

  [string]$AiDisclosure = 'AI-generated image.',

  [int]$MaxKeywords = 50,

  [string]$ExifToolPath = '',

  [switch]$NoInstallExifTool,

  [switch]$Recurse,

  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$PathValue, [bool]$MustExist = $false) {
  if([string]::IsNullOrWhiteSpace($PathValue)) { return '' }
  if($MustExist) {
    return (Resolve-Path -LiteralPath $PathValue).Path
  }
  $expanded = [Environment]::ExpandEnvironmentVariables($PathValue)
  if([System.IO.Path]::IsPathRooted($expanded)) {
    return [System.IO.Path]::GetFullPath($expanded)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $expanded))
}

function Get-ScriptRoot {
  if($PSScriptRoot) { return $PSScriptRoot }
  return (Get-Location).Path
}

function Install-ExifToolPortable {
  $root = Get-ScriptRoot
  $toolDir = Join-Path $root 'tools\exiftool'
  $exe = Join-Path $toolDir 'exiftool.exe'
  if(Test-Path -LiteralPath $exe) { return $exe }

  Write-Host 'ExifTool not found. Downloading portable ExifTool from exiftool.org...' -ForegroundColor Yellow
  New-Item -ItemType Directory -Path $toolDir -Force | Out-Null

  $page = Invoke-WebRequest -Uri 'https://exiftool.org/' -UseBasicParsing
  $match = [regex]::Match($page.Content, 'href=["''](?<href>[^"'']*exiftool-[^"'']*_64\.zip(?:/download)?[^"'']*)["'']', 'IgnoreCase')
  if(-not $match.Success) {
    throw 'Could not find the Windows 64-bit ExifTool ZIP link on exiftool.org. Install ExifTool manually or pass -ExifToolPath.'
  }

  $href = $match.Groups['href'].Value
  if($href -notmatch '^https?://') {
    $href = 'https://exiftool.org/' + $href.TrimStart('/')
  }

  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('exiftool-' + [guid]::NewGuid().ToString('N'))
  $zip = Join-Path $tmp 'exiftool.zip'
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  try {
    Invoke-WebRequest -Uri $href -OutFile $zip -UseBasicParsing
    Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
    $downloadedExe = Get-ChildItem -LiteralPath $tmp -Recurse -Filter 'exiftool*.exe' | Select-Object -First 1
    if(-not $downloadedExe) { throw 'Downloaded ExifTool ZIP did not contain an executable.' }
    Copy-Item -LiteralPath $downloadedExe.FullName -Destination $exe -Force

    $supportDir = Get-ChildItem -LiteralPath $tmp -Recurse -Directory -Filter 'exiftool_files' | Select-Object -First 1
    if($supportDir) {
      $destSupportDir = Join-Path $toolDir 'exiftool_files'
      if(Test-Path -LiteralPath $destSupportDir) {
        Remove-Item -LiteralPath $destSupportDir -Recurse -Force
      }
      Copy-Item -LiteralPath $supportDir.FullName -Destination $destSupportDir -Recurse -Force
    }
  } finally {
    if(Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
  }

  return $exe
}

function Find-ExifTool {
  if(-not [string]::IsNullOrWhiteSpace($ExifToolPath)) {
    $p = Resolve-FullPath $ExifToolPath $true
    if(-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "ExifToolPath is not a file: $p" }
    return $p
  }

  $cmd = Get-Command exiftool -ErrorAction SilentlyContinue
  if($cmd) { return $cmd.Source }

  $installedCandidates = @(
    "$env:LOCALAPPDATA\Programs\ExifTool\ExifTool.exe",
    "$env:ProgramFiles\ExifTool\ExifTool.exe",
    "${env:ProgramFiles(x86)}\ExifTool\ExifTool.exe"
  )
  foreach($candidate in $installedCandidates) {
    if(-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  $local = Join-Path (Get-ScriptRoot) 'tools\exiftool\exiftool.exe'
  if(Test-Path -LiteralPath $local) { return $local }

  if($NoInstallExifTool) {
    throw 'ExifTool was not found. Install it, add it to PATH, or pass -ExifToolPath.'
  }

  return Install-ExifToolPortable
}

function Get-FirstValue($Row, [string[]]$Names) {
  foreach($name in $Names) {
    if($Row.PSObject.Properties.Name -contains $name) {
      $value = $Row.$name
      if($null -ne $value) { return [string]$value }
    }
  }
  return ''
}

function Limit-Text([string]$Value, [int]$Max) {
  $raw = ''
  if($null -ne $Value) { $raw = [string]$Value }
  $v = $raw.Trim() -replace '\s+', ' '
  if($Max -gt 0 -and $v.Length -gt $Max) {
    $v = $v.Substring(0, $Max).Trim()
  }
  return $v
}

function Normalize-Keywords([string]$Value, [int]$Max, [bool]$AddAiKeyword) {
  $keywordSource = ''
  if($null -ne $Value) { $keywordSource = [string]$Value }
  $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  $items = New-Object 'System.Collections.Generic.List[string]'

  if($AddAiKeyword) {
    [void]$seen.Add('ai generated')
    $items.Add('ai generated')
  }

  foreach($part in ($keywordSource -split "[,;`r`n]+")) {
    $kw = ($part.Trim() -replace '\s+', ' ')
    if($kw.Length -eq 0) { continue }
    if($kw.Length -gt 64) { $kw = $kw.Substring(0,64).Trim() }
    if($seen.Add($kw)) { $items.Add($kw) }
    if($items.Count -ge $Max) { break }
  }

  return @($items)
}

function Ensure-AiDisclosure([string]$Description, [string]$Disclosure) {
  $desc = ''
  if($null -ne $Description) { $desc = [string]$Description }
  $desc = $desc.Trim()
  if($AiMode -ne 'ai') { return $desc }
  $disc = ''
  if($null -ne $Disclosure) { $disc = [string]$Disclosure }
  $disc = $disc.Trim()
  if($disc.Length -eq 0) { return $desc }
  if($desc -match '(?i)\bAI[- ]generated\b') { return $desc }
  return ($disc + ' ' + $desc).Trim()
}

function Build-ImageIndex([string]$Root, [bool]$UseRecurse) {
  $opt = @{}
  if($UseRecurse) { $opt.Recurse = $true }
  $files = Get-ChildItem -LiteralPath $Root -File @opt
  $index = @{}
  foreach($f in $files) {
    $key = $f.Name.ToLowerInvariant()
    if(-not $index.ContainsKey($key)) { $index[$key] = New-Object 'System.Collections.Generic.List[object]' }
    $index[$key].Add($f)

    $baseKey = $f.BaseName.ToLowerInvariant()
    if(-not $index.ContainsKey($baseKey)) { $index[$baseKey] = New-Object 'System.Collections.Generic.List[object]' }
    $index[$baseKey].Add($f)
  }
  return $index
}

function Find-ImageForCsvRow($Index, [string]$Filename) {
  $name = ''
  if($null -ne $Filename) { $name = [string]$Filename }
  $name = $name.Trim()
  if($name.Length -eq 0) { return $null }
  $keys = @($name.ToLowerInvariant())
  $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
  if($base) { $keys += $base.ToLowerInvariant() }

  foreach($key in $keys) {
    if($Index.ContainsKey($key)) {
      $matches = $Index[$key]
      if($matches.Count -eq 1) { return $matches[0] }
      return [pscustomobject]@{ Ambiguous = $true; Count = $matches.Count; Name = $name }
    }
  }
  return $null
}

function Invoke-ExifToolWrite([string]$ExifTool, [string]$File, [string]$Title, [string]$Description, [string[]]$Keywords) {
  $keywordString = ($Keywords -join ', ')
  $objectName = Limit-Text $Title 64
  $creatorTool = if([string]::IsNullOrWhiteSpace($AiModel)) { 'MetaGen Dreamstime Embed' } else { "MetaGen Dreamstime Embed; $AiModel" }

  $args = @(
    '-overwrite_original',
    '-charset', 'IPTC=UTF8',
    '-sep', ', ',
    '-IPTC:CodedCharacterSet=UTF8',
    "-IPTC:ObjectName=$objectName",
    "-IPTC:Headline=$Title",
    "-XMP-dc:Title=$Title",
    "-IPTC:Caption-Abstract=$Description",
    "-XMP-dc:Description=$Description",
    "-EXIF:ImageDescription=$Description",
    "-IPTC:Keywords=$keywordString",
    "-XMP-dc:Subject=$keywordString",
    "-XMP:CreatorTool=$creatorTool",
    '-Software=MetaGen Dreamstime Embed'
  )

  if($AiMode -eq 'ai') {
    $args += '-XMP-iptcExt:DigitalSourceType=http://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia'
  }

  $args += $File
  $output = & $ExifTool @args 2>&1
  $code = $LASTEXITCODE
  return [pscustomobject]@{ ExitCode = $code; Output = ($output -join "`n") }
}

function Invoke-ExifToolVerify([string]$ExifTool, [string]$File) {
  $args = @(
    '-j',
    '-charset', 'IPTC=UTF8',
    '-IPTC:Headline',
    '-XMP-dc:Title',
    '-IPTC:Caption-Abstract',
    '-XMP-dc:Description',
    '-IPTC:Keywords',
    '-XMP-dc:Subject',
    '-XMP-iptcExt:DigitalSourceType',
    $File
  )
  $json = & $ExifTool @args 2>$null
  if($LASTEXITCODE -ne 0 -or -not $json) { return $null }
  return ($json -join "`n") | ConvertFrom-Json
}

$csvPath = Resolve-FullPath $Csv $true
$imagesPath = Resolve-FullPath $ImagesDir $true
if(-not (Test-Path -LiteralPath $imagesPath -PathType Container)) { throw "ImagesDir is not a folder: $imagesPath" }

if([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path (Split-Path -Parent $csvPath) 'dreamstime-ready'
}
$outPath = Resolve-FullPath $OutDir $false
$outRootForCheck = $outPath.TrimEnd('\') + '\'

if($imagesPath.TrimEnd('\') -ieq $outPath.TrimEnd('\')) {
  throw 'OutDir must be different from ImagesDir so source images are never modified.'
}

$exifTool = if($DryRun) { '(dry-run; ExifTool not required)' } else { Find-ExifTool }
$rows = @(Import-Csv -LiteralPath $csvPath)
if($rows.Count -eq 0) { throw "CSV has no rows: $csvPath" }

if(-not $DryRun) {
  New-Item -ItemType Directory -Path $outPath -Force | Out-Null
}

$index = Build-ImageIndex $imagesPath ([bool]$Recurse)
$report = New-Object 'System.Collections.Generic.List[object]'
$processed = 0
$skipped = 0

foreach($row in $rows) {
  $filename = Get-FirstValue $row @('Filename','File name','file_name','filename','File Name')
  $title = Limit-Text (Get-FirstValue $row @('Image Name','Title','title','Caption')) 200
  $description = Limit-Text (Ensure-AiDisclosure (Get-FirstValue $row @('Description','description','Caption-Abstract')) $AiDisclosure) 1000
  $keywords = Normalize-Keywords (Get-FirstValue $row @('keywords','Keywords','tags','Tags')) $MaxKeywords ($AiMode -eq 'ai')

  $status = 'ok'
  $message = ''
  $source = Find-ImageForCsvRow $index $filename

  if($null -eq $source) {
    $status = 'missing'
    $message = 'Source image not found'
    $skipped++
  } elseif($source.PSObject.Properties.Name -contains 'Ambiguous') {
    $status = 'ambiguous'
    $message = "Multiple source images matched ($($source.Count))"
    $skipped++
  } elseif([string]::IsNullOrWhiteSpace($title) -or [string]::IsNullOrWhiteSpace($description) -or $keywords.Count -eq 0) {
    $status = 'invalid'
    $message = 'Missing title, description, or keywords in CSV row'
    $skipped++
  } else {
    $dest = Join-Path $outPath $source.Name
    $destFull = [System.IO.Path]::GetFullPath($dest)
    if(-not $destFull.StartsWith($outRootForCheck, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Resolved output path escaped OutDir: $destFull"
    }

    if($source.Extension -notmatch '^\.(jpg|jpeg)$') {
      $message = 'Warning: Dreamstime normally requires JPG; copied file is not JPG.'
    }

    if($DryRun) {
      $status = 'dry-run'
      $processed++
    } else {
      Copy-Item -LiteralPath $source.FullName -Destination $destFull -Force
      $write = Invoke-ExifToolWrite $exifTool $destFull $title $description $keywords
      if($write.ExitCode -ne 0) {
        $status = 'write-error'
        $message = $write.Output
        $skipped++
      } else {
        $verify = Invoke-ExifToolVerify $exifTool $destFull
        if($null -eq $verify) {
          $status = 'verify-warning'
          $message = 'ExifTool write completed, but verify read failed.'
        } else {
          $hasTitle = (Get-FirstValue $verify[0] @('Headline','Title')).Length -gt 0
          $hasDesc = (Get-FirstValue $verify[0] @('Caption-Abstract','CaptionAbstract','Description')).Length -gt 0
          $hasKeywords = (Get-FirstValue $verify[0] @('Keywords','Subject')).Length -gt 0
          if(-not ($hasTitle -and $hasDesc -and $hasKeywords)) {
            $status = 'verify-warning'
            $message = 'Some expected metadata fields were not readable after write.'
          }
        }
        $processed++
      }
    }
  }

  $report.Add([pscustomobject]@{
    Filename = $filename
    Status = $status
    Keywords = $keywords.Count
    Title = $title
    SourcePath = if($source -and -not ($source.PSObject.Properties.Name -contains 'Ambiguous')) { $source.FullName } else { '' }
    OutputPath = if($source -and -not ($source.PSObject.Properties.Name -contains 'Ambiguous') -and $status -in @('ok','verify-warning','dry-run')) { Join-Path $outPath $source.Name } else { '' }
    Message = $message
  })
}

if(-not $DryRun) {
  $reportPath = Join-Path $outPath 'dreamstime-embed-report.csv'
  $report | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding UTF8
}

Write-Host ''
Write-Host "Dreamstime metadata embed complete" -ForegroundColor Green
Write-Host "CSV:       $csvPath"
Write-Host "Images:    $imagesPath"
Write-Host "Output:    $outPath"
Write-Host "ExifTool:  $exifTool"
Write-Host "Processed: $processed"
Write-Host "Skipped:   $skipped"
if(-not $DryRun) {
  Write-Host "Report:    $(Join-Path $outPath 'dreamstime-embed-report.csv')"
}
