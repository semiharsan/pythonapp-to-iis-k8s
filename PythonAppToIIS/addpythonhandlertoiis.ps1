param([string] $PythonPath,
      [string] $PythonArguments
     )

Write-Output "PythonPath = $PythonPath"
Write-Output "PythonArguments = $PythonArguments"

#Add IIS WebHandler
Write-Host "`nGetting Web Handler settings ..."
If ((Get-WebHandler -Name "PythonHandler") -ne $Null) {
    Write-Host "Python Webhandler already configured"
}
Else {
    Write-Host "Adding Python Webhandler to IIS Handlers mappings"
    add-webconfiguration 'system.webServer/handlers' -Value @{
        Name            = "PythonHandler";
        Modules         = "FastCgiModule";
        ScriptProcessor = "$PythonPath|`"$PythonArguments`"";
        Path            = "*";
        Verb            = "*";
        RequiredAccess  = "Script";
    }
}

#Get FastCGI settings
Write-Host "`nGetting FastCGI configuration."
$FastCGIConfig = get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/fastCgi" -Name "." -Recurse | Select-Object -ExpandProperty collection | Select-Object fullpath, arguments
#Set FastCGI settings if they are missing
If ($FastCGIConfig.fullpath -eq $PythonPath) {
    Write-Host "FastCCGI config already set"
}
Else {
    Write-Host "Settings FastCGI config settings"
    Write-Verbose "FullPath: $PythonPath" -Verbose
    Write-Verbose "Arguments: $PythonArguments" -Verbose
    ADD-WebConfigurationProperty `
        -pspath 'MACHINE/WEBROOT/APPHOST'  `
        -filter "system.webServer/fastCgi" `
        -name "." `
        -value @{fullPath = "$PythonPath"; arguments = "`"$PythonArguments`"" }
}
