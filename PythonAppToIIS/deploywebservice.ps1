param([string] $SiteName,
      [string] $HostName,
      [string] $AppRuntimeVersion,
      [string] $AppPipelineMode
     )

set-variable -Name "SitePath" -Value "$env:systemdrive\inetpub\wwwroot\$SiteName"
set-variable -Name "LogPath" -Value "$env:systemdrive\inetpub\logs\Logfiles\$SiteName"
set-variable -Name "SourceFiles" -Value "$env:SYSTEM_ARTIFACTSDIRECTORY\$env:BUILD_DEFINITIONNAME\PythonAppToIIS\App"

Write-Output "SiteName = $SiteName"
Write-Output "SitePath = $SitePath"
Write-Output "LogPath = $LogPath"
Write-Output "HostName = $HostName"
Write-Output "AppRuntimeVersion = $AppRuntimeVersion"
Write-Output "AppPipelineMode = $AppPipelineMode"
Write-Output "Source Files Folder = $SourceFiles"
Write-Output "End Of Variables"

function Create-SitePath
{
    if (Test-Path -Path $SitePath -PathType Container)
    {
        Write-Output "Website folder $SitePath already exists"
    }
    else
    {
        Write-Output "Website folder $SitePath does not exist, creating it..."
        New-Item -Path $SitePath -ItemType Directory   
    }
}
Create-SitePath

function Create-LogPath
{
    if (Test-Path -Path $LogPath -PathType Container)
    {
        Write-Output "Website Log folder $LogPath already exists"
    }
    else
    {
        Write-Output "Website Log folder $LogPath does not exist, creating it..."
        New-Item -Path $LogPath -ItemType Directory   
    }
}
Create-LogPath

function Create-AppPool
{
    $appPool = Get-WebAppPoolState -Name $SiteName -ErrorAction SilentlyContinue
    if ($appPool.Value -eq "Started")
    {
        Write-Output "Application pool already exists: $SiteName"
    }
    else
    {
        Write-Output "Creating Application pool: $SiteName"
        New-WebAppPool -Name $SiteName
        Set-ItemProperty "IIS:\AppPools\$SiteName" managedRuntimeVersion $AppRuntimeVersion
        Set-ItemProperty "IIS:\AppPools\$SiteName" managedPipelineMode $AppPipelineMode
        Set-ItemProperty "IIS:\AppPools\$SiteName" -name processModel.identityType -Value LocalSystem   
    }
}
Create-AppPool

function Create-Or-Update-WebSite
{
    if((Get-Website -Name $SiteName) -ne $null)
    {
	Write-Output "Website already exists, let us update = $website"
	Stop-WebSite -Name $SiteName
	$KaynakDosyalar=@(Get-ChildItem -Path $SourceFiles).Count
	Write-Output "Kaynak Dosya Sayisi = $KaynakDosyalar"
        Remove-Item -Path $SitePath\* -Force -Recurse
	Copy-Item -Path $SourceFiles\* $SitePath -force -recurse
	$HedefDosyalar=@(Get-ChildItem -Path $SitePath).Count
	Write-Output "Hedef Dosya Sayisi = $HedefDosyalar"
        Start-Website -Name $SiteName	
    }
    else
    {
        Write-Output "Let us create Web Site $SiteName"
	$KaynakDosyalar=@(Get-ChildItem -Path $SourceFiles).Count
	Write-Output "Kaynak Dosya Sayisi = $KaynakDosyalar"
	Copy-Item -Path $SourceFiles\* $SitePath -force -recurse
	$HedefDosyalar=@(Get-ChildItem -Path $SitePath).Count
	Write-Output "Hedef Dosya Sayisi = $HedefDosyalar"
	New-WebSite -Name $SiteName -Port 80 -HostHeader $HostName -PhysicalPath $SitePath -ApplicationPool $SiteName 
	Set-ItemProperty IIS:\Sites\$SiteName -name logFile.directory -value $LogPath
        Set-ItemProperty IIS:\Sites\$SiteName -name logFile.logExtFileFlags -value "BytesRecv, BytesSent, ClientIP, ComputerName, Date, Host, HttpStatus, HttpSubStatus, Method, ProtocolVersion, Referer, ServerIP, ServerPort, SiteName, Time, TimeTaken, UriQuery, UriStem, UserAgent, UserName, Win32Status"
        Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='$SiteName']/logFile/customFields" -name "." -value @{logFieldName='X-Real-IP';sourceName='X-Real-IP';sourceType='RequestHeader'}
    }
}
Create-Or-Update-WebSite
