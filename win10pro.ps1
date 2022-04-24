[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = "pbatard/Fido"
$releases = "https://api.github.com/repos/$repo/releases"

Write-Host Determining latest release
$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name

$download = "https://github.com/pbatard/Fido/archive/refs/tags/${tag}.zip"
$zipfile = Split-Path -Path $download -Leaf
$dirname = $zipfile -replace '.*\.zip$',''

Write-Host "Downloading latest release"
Invoke-WebRequest -UseBasicParsing -Uri $download -OutFile $zipfile

Write-Host "Extracting release files"
Expand-Archive $zipfile -Force

Remove-Item -Path $zipfile -Recurse -Force -ErrorAction SilentlyContinue 

[System.String]$FidoFile = Get-ChildItem -Path ".\${dirname}" -Recurse -Filter "Fido.ps1" | Select-Object -ExpandProperty FullName

[System.String]$DownloadLink = & $FidoFile -Win 10 -Rel 21H2 -Ed Pro -Lang English -Arch x64 -GetUrl

Invoke-WebRequest -UseBasicParsing -Uri $DownloadLink -OutFile Win10_21H2_English_x64.iso -ContentType "application/octet-stream"

[System.String]$IsoFile = Get-ChildItem -Path . -Recurse -Filter "*.iso" | Select-Object -ExpandProperty FullName

$iso = Mount-DiskImage -ImagePath $IsoFile -Access ReadOnly -StorageType ISO
[System.String]$DriveLetter = $($iso |Get-Volume |Select-Object -ExpandProperty DriveLetter) + ":"
[System.String]$InstallWIM = Get-ChildItem -Path "${DriveLetter}\" -Recurse -Filter "install.wim" | Select-Object -ExpandProperty FullName
New-Item -Path $env:TMP -ItemType Directory -Name "win10_mount" -Force -Confirm:$false
[System.String]$ImageIndex = Get-WindowsImage -ImagePath $InstallWIM | Where-Object -FilterScript {$_.ImageName -match '^Windows 10 Pro$'} | Select-Object -ExpandProperty ImageIndex
Mount-WindowsImage -ImagePath $InstallWIM -Index $ImageIndex -Path "${env:TMP}\win10_mount" -ReadOnly 

Get-AppxProvisionedPackage -Path "${env:TMP}\win10_mount"
