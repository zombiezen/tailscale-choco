$channel = "https://pkgs.tailscale.com/stable/"

$meta = Invoke-WebRequest ($channel + "?mode=json&os=windows") | ConvertFrom-Json

$url = $channel + $meta.Exes[0]
$version = $meta.Version

$hash = (Get-FileHash -Algorithm SHA256 -InputStream ([System.Net.WebClient]::new().OpenRead($url))).Hash.ToLower()

# Update the nuspec
$nuspec = New-Object xml
$nuspec.Load("./tailscale.nuspec")
$nuspec.package.metadata.version = $version
$nuspec.Save("./tailscale.nuspec")

# Update the installer script
$installer = Get-Content "./tools/chocolateyinstall.ps1"
$installer = $installer -replace "https:\/\/pkgs.tailscale.com\/.*\.exe", $url
$installer = $installer -replace "[0-9a-f]{64}", $hash
$installer | Out-File "./tools/chocolateyinstall.ps1"

# Check and see if files have been updated
$files_modified = $(git diff --name-only HEAD) -split '\n'
if ($files_modified.length -gt 0) {
    git commit -a -m "Update to version $version"
}