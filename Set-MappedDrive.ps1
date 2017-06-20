<#	
	.NOTES
	===========================================================================
	 Created on:   	10/01/2017 1:53 PM
	 Created by:   	<author>
	 Organization: 	<company>
	 Filename:     	Set-MappedDrive.ps1
	===========================================================================
	.DESCRIPTION
		Check the existing mappings on a user machines, remove the existing server 
		mapping and remap to new server keeping the folder hierarchy intact.
#>

function Set-Logs
{
	[CmdletBinding()]
	Param (
		[Parameter( Mandatory=$true, Position=1, ValueFromPipeline=$true)]
		[PSObject] $Content
	)
	
	$Content | Out-File -FilePath $logPath -Append
}

Clear-Host
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$csvDetails = Import-Csv -Path "$PSScriptRoot\<file name>.csv"
$dateTime = Get-Date -UFormat "%d%m%Y_%H%M%Sp"
$filePath = $env:APPLOGSU
$logPath = "$filePath\mapping_$dateTime.log"
$hostName = $env:COMPUTERNAME
$userName = $env:USERNAME
$startTime = Get-Date -Format F
$arrayPre = @()
$arrayPost = @()

Set-Logs -Content "*************************************************"
Set-Logs -Content "Start Logging $startTime"
Set-Logs -Content "*************************************************"
Set-Logs -Content ""
foreach ($csvSD in $csvDetails)
{
	$oldFileServer = $csvSD.OldServer
	$newFileServer = $csvSD.NewServer
	
	# Get the current mapping of the user drive
	$currentSharesPre = Get-CimInstance -ClassName Win32_MappedLogicalDisk -ComputerName $hostName | Select-Object @{ n = "DriveName"; e = { $_.DeviceID } }, @{ n = "ComputerName"; e = { $_.SystemName } }, @{ n = "ShareLocation"; e = { $_.ProviderName } }
	
	# Traverse through the mapping values picking up the drive id and share location.
	foreach ($cSPre in $currentSharesPre)
	{
		$shareObjPre = New-Object System.Management.Automation.PSObject
		$shareObjPre | Add-Member -MemberType NoteProperty -Name "DriveName" -Value $cSPre.DriveName
		$shareObjPre | Add-Member -MemberType NoteProperty -Name "ShareLocation" -Value $cSPre.ShareLocation
		$shareObjPre | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $cSPre.ComputerName
		$shareObjPre | Add-Member -MemberType NoteProperty -Name "LoggedOnName" -Value $userName
		$arrayPre += $shareObjPre
	
		# if a match is found, remap to the new location.
		if ($shareObjPre.ShareLocation -like "\\$oldFileServer\*")
		{
			$driveLetter = $shareObjPre.DriveName
			$sharePath = $shareObjPre.ShareLocation
			
			try
			{
				# drop current mapping.
				$outputD = Invoke-Expression -Command "net use $driveLetter /delete /y 2>&1" -ErrorAction Stop -ErrorVariable err
			}
			catch [System.Exception]
			{
				$ErrorDetails = ($err[0].Exception -split [System.Environment]::NewLine)[-1]
			}
			
			Set-Logs -Content "UnMapping Result:: $outputD"
			
			#remap to new location. [regex]::Escape >>>Interpret as literal character rather than as metacharacter. 
			$newSharePath = $sharePath -Replace ([regex]::Escape("$oldFileServer"), "$newFileServer")
			try
			{ 
				$outputM = Invoke-Expression -Command "net use $driveLetter $newSharePath /P:Yes 2>&1" -ErrorAction Stop -ErrorVariable err
			}
			catch [System.Exception]
			{
				$ErrorDetails = ($err[0].Exception -split [System.Environment]::NewLine)[-1]
			}
			Set-Logs -Content "Remapping Result:: $outputM"
		}
	}
	
	$currentSharesPost = Get-CimInstance -ClassName Win32_MappedLogicalDisk -ComputerName $hostName | Select-Object @{ n = "DriveName"; e = { $_.DeviceID } }, @{ n = "ComputerName"; e = { $_.SystemName } }, @{ n = "ShareLocation"; e = { $_.ProviderName } }
	foreach ($cSPost in $currentSharesPost)
	{
		$shareObjPost = New-Object System.Management.Automation.PSObject
		$shareObjPost | Add-Member -MemberType NoteProperty -Name "DriveName" -Value $cSPost.DriveName
		$shareObjPost | Add-Member -MemberType NoteProperty -Name "ShareLocation" -Value $cSPost.ShareLocation
		$shareObjPost | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $cSPost.ComputerName
		$shareObjPost | Add-Member -MemberType NoteProperty -Name "LoggedOnName" -Value $userName
		$arrayPost += $shareObjPost
	}
}
Set-Logs -Content ""
Set-Logs -Content ""
Set-Logs -Content "**************OLD MAPPING RECORD*************"
Set-Logs -Content $arrayPre
Set-Logs -Content "*********************************************"
Set-Logs -Content ""
Set-Logs -Content "**************NEW MAPPING RECORD*************"
Set-Logs -Content $arrayPost
Set-Logs -Content "*********************************************"
Set-Logs -Content ""

$endTime = Get-Date -Format F
Set-Logs -Content "*************************************************"
Set-Logs -Content "End Logging $endTime"
Set-Logs -Content "*************************************************"

