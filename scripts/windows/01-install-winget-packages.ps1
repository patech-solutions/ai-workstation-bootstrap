[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Ollama is intentionally NOT installed on Windows.
# Ollama runs native inside WSL to avoid Windows/WSL NAT and localhost forwarding issues.

$packages = @(
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Docker.DockerDesktop",
    "Microsoft.PowerShell",
    "OpenJS.NodeJS.LTS",
    "Python.Python.3.12",
    "7zip.7zip",
    "Notepad++.Notepad++",
    "WinSCP.WinSCP"
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg"
    winget install --id $pkg --exact --source winget --accept-package-agreements --accept-source-agreements
}
