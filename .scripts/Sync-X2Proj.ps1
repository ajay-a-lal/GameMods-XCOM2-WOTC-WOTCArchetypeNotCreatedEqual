<#
.SYNOPSIS
    Syncs the XCOM 2 .x2proj file in the inner project folder by updating existing ItemGroups.
    Run always from the outer/root repo folder.
#>

# Hard-coded inner project folder name
$projectFolderName = "WOTCArchetypeNotCreatedEqual"

# Build full path to project directory
$projectDir = Join-Path (Get-Location).Path $projectFolderName

if (-not (Test-Path $projectDir -PathType Container)) {
    Write-Error "Project folder not found: $projectDir"
    Write-Host "Run this from the outer/root folder (the one containing .scripts)."
    exit 1
}

# Find the .x2proj
$projFile = Get-ChildItem -Path $projectDir -Filter "*.x2proj" | 
            Select-Object -First 1 -ExpandProperty FullName

if (-not $projFile) {
    Write-Error "No .x2proj found in $projectDir"
    exit 1
}

Write-Host "Updating: $projFile"
Write-Host "Project dir: $projectDir"

# Load XML (preserve whitespace & format as much as possible)
$xml = [xml](Get-Content $projFile -Raw)

# Root path for relatives
$rootPath = $projectDir.TrimEnd('\','/')

# Collect folders (relative, trailing \)
$folders = Get-ChildItem -Path $projectDir -Recurse -Directory | 
    ForEach-Object {
        $rel = $_.FullName.Substring($rootPath.Length).TrimStart('\','/')
        if ($rel) { "$rel\" }
    } | Sort-Object

# Collect files (exclude .x2proj)
$files = Get-ChildItem -Path $projectDir -Recurse -File | 
    Where-Object { $_.FullName -ne $projFile } | 
    ForEach-Object {
        $_.FullName.Substring($rootPath.Length).TrimStart('\','/')
    } | Sort-Object

# Find or create Folder ItemGroup
$folderGroup = $xml.Project.ItemGroup | Where-Object { $_.Folder } | Select-Object -First 1
if (-not $folderGroup) {
    $folderGroup = $xml.CreateElement("ItemGroup")
    $xml.Project.AppendChild($folderGroup) | Out-Null
}
$folderGroup.RemoveAll()  # Clear old children
foreach ($folder in $folders) {
    $elem = $xml.CreateElement("Folder", $xml.Project.NamespaceURI)
    $elem.SetAttribute("Include", $folder)
    if ($elem.HasAttribute("xmlns")) {
        $elem.Attributes.RemoveNamedItem("xmlns") | Out-Null
    }
    $folderGroup.AppendChild($elem) | Out-Null
}

# Find or create Content ItemGroup
$contentGroup = $xml.Project.ItemGroup | Where-Object { $_.Content } | Select-Object -First 1
if (-not $contentGroup) {
    $contentGroup = $xml.CreateElement("ItemGroup")
    $xml.Project.AppendChild($contentGroup) | Out-Null
}
$contentGroup.RemoveAll()  # Clear old children
foreach ($file in $files) {
    $elem = $xml.CreateElement("Content", $xml.Project.NamespaceURI)
    $elem.SetAttribute("Include", $file)
    if ($elem.HasAttribute("xmlns")) {
        $elem.Attributes.RemoveNamedItem("xmlns") | Out-Null
    }
    $contentGroup.AppendChild($elem) | Out-Null
}

$xml.Save($projFile)

Write-Host "Success!" -ForegroundColor Green
Write-Host "  Folders: $($folders.Count)"
Write-Host "  Files:   $($files.Count)"
