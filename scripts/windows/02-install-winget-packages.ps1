$PackageFile = Join-Path $PSScriptRoot "..\..\config\winget-packages.txt"

if (!(Test-Path $PackageFile)) {
    throw "Package file not found: $PackageFile"
}

Get-Content $PackageFile | ForEach-Object {
    $pkg = $_.Trim()
    if ($pkg -and -not $pkg.StartsWith("#")) {
        Write-Host "Installing $pkg"
        winget install --id $pkg --exact --source winget --accept-package-agreements --accept-source-agreements
    }
}
