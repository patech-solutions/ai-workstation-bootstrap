[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Ollama is intentionally NOT installed on Windows.
# Ollama runs native inside WSL to avoid Windows/WSL NAT and localhost forwarding issues.

$packages = @(
    "Git.Git",
    "Microsoft.VisualStudioCode",
    # Docker Desktop wordt NIET geïnstalleerd.
    # Native docker-ce wordt geïnstalleerd in WSL2 via 01-dev-tools.sh.
    # Docker Desktop containers zitten in een geïsoleerd netwerk (eigen VM) en
    # kunnen Ollama in WSL2 niet bereiken zonder Windows-zijdige poortproxy.
    "Microsoft.PowerShell",
    "OpenJS.NodeJS.LTS",
    "Python.Python.3.12",
    "7zip.7zip",
    "Notepad++.Notepad++",
    "WinSCP.WinSCP",
    "JohnMacFarlane.Pandoc"
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg"
    winget install --id $pkg --exact --source winget --accept-package-agreements --accept-source-agreements
}
