$pythonVersion="3.13.0"
$pythonInstallerUrl="https://www.python.org/ftp/python/$pythonVersion/python-${pythonVersion}a1-amd64.exe"
$pythonInstallerPath="$env:TEMP\python-installer.exe"
$pythonInstallPath="C:\Program Files\Python"
mkdir $pythonInstallPath

Write-Host "Download the Python installer"
Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $pythonInstallerPath

Write-Host "Install Python"
Start-Process -FilePath $pythonInstallerPath -ArgumentList "/quiet InstallAllUsers=1 TargetDir=`"$pythonInstallPath`" PrependPath=1" -Wait


Write-Host "Clean up the installer"
Remove-Item $pythonInstallerPath

Write-Host "Add Python to the PATH environment variable"
[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pythonInstallPath", [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pythonInstallPath\Scripts", [System.EnvironmentVariableTarget]::Machine)

Write-Host "Check python version"
python --version
