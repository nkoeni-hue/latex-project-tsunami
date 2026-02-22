Write-Host "🧹 Cleaning Overleaf/Git LaTeX project..."

# 1. Extract figure names from .tex files
Get-ChildItem -Filter *.tex | ForEach-Object {
    Select-String -Path $_.FullName -Pattern '\\includegraphics(?:\[[^\]]*\])?\{([^\}]+)\}' -AllMatches |
    ForEach-Object { $_.Matches.Groups[1].Value }
} | Sort-Object -Unique | Set-Content used_figs.txt

# 2. Create clean folder
New-Item -ItemType Directory -Force -Path "clean_project\figures" | Out-Null

# 3. Copy used figures (search in project and figures folder)
$extensions = @(".pdf", ".png", ".jpg", ".jpeg", ".eps")
$searchDirs = @(".", "figures")

Get-Content used_figs.txt | ForEach-Object {
    $name = $_
    $found = $false

    foreach ($dir in $searchDirs) {
        foreach ($ext in $extensions) {
            $candidate = Join-Path $dir $name
            if (-not (Test-Path $candidate) -and -not ($candidate -match "\.")) {
                $candidate = $candidate + $ext
            }
            if (Test-Path $candidate) {
                $found = $true
                $src = $candidate
                $dest = Join-Path "clean_project" $src
                New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
                Copy-Item $src $dest -Force
                break
            }
        }
        if ($found) { break }
    }

    if (-not $found) {
        Write-Host "⚠️ Could not find figure: $name"
    }
}

# 4. Copy main LaTeX and support files
if (Test-Path "main.tex") { Copy-Item main.tex clean_project -Force }
Get-ChildItem -Include *.bib,*.sty,*.cls -Path . -Recurse | Copy-Item -Destination clean_project -Force -ErrorAction SilentlyContinue

Write-Host "✅ Clean project created in 'clean_project\'"
