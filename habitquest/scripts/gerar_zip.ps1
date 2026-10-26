# Gera habitquest_entrega.zip contendo EXCLUSIVAMENTE a pasta lib/ e o pubspec.yaml.
# Uso (na raiz do projeto):  powershell -ExecutionPolicy Bypass -File scripts/gerar_zip.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $PSScriptRoot
$zipPath = Join-Path $root 'habitquest_entrega.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')
try {
    $files = @(Get-Item (Join-Path $root 'pubspec.yaml')) + @(Get-ChildItem (Join-Path $root 'lib') -Recurse -File)
    foreach ($file in $files) {
        # Caminho relativo com "/" para funcionar em Windows, Linux e macOS.
        $entry = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entry) | Out-Null
    }
} finally {
    $zip.Dispose()
}

Write-Host "ZIP gerado: $zipPath ($($files.Count) arquivos)"
