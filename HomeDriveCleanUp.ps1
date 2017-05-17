<#	
	.NOTES
	===========================================================================
	 Created on:   	9/1/2016 08:00 AM
	 Created by:   	<author>
	 Organization: 	<company>
	 Filename:     	CleanUp-HomeDrive.ps1
	===========================================================================
	.DESCRIPTION
		Cleanup users content from home drive (H:).
		
	.EXAMPLE
		./HomeDriveCleanUp.ps1
#>
$currentTimeStamp = "[" + ((Get-Date).ToShortDateString()) + " " + ((Get-Date).ToShortTimeString()) + "]"
$fileDateTime = Get-Date -UFormat "%d%b%YT%I%M%p"
$older = (Get-Date).AddDays(-30)
$currentPath = Split-Path -parent $MyInvocation.MyCommand.Definition
$homedriveListing = $currentPath + "\homedrivePaths.csv"
$logs = $currentPath + "\logs_$fileDateTime.log"

$fileDetails = Get-ChildItem *.log | Select-Object @{ Name = "FullName"; Expression = { $_.FullName } }, @{ Name = "CreationTime"; Expression = { $_.CreationTime } }
if ($fileDetails.CreationTime -lt $older)
{
	Remove-Item "$currentPath\*.log" -Force
}

$csvFileImport = Import-Csv $homedriveListing
foreach ($csvFile in $csvFileImport)
{
	$userDirectory = Get-ChildItem -Path $csvFile.Paths -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
	foreach ($userD in $userDirectory)
	{
		$contentCount = Get-ChildItem -Path $userD -ErrorAction SilentlyContinue | Measure-Object
		
		if ($contentCount.Count -ne 0)
		{
			#$content = Get-ChildItem -Path $userD -ErrorAction SilentlyContinue -Recurse | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $older} | Select-Object @{ Name = "FullName"; Expression = { $_.FullName } }, @{ Name = "ModifiedTime"; Expression = { $_.LastWriteTime } }
			$content = Get-ChildItem -Path $userD -ErrorAction SilentlyContinue -Recurse | Where-Object { $_.LastWriteTime -lt $older } | Select-Object @{ Name = "FullName"; Expression = { $_.FullName } }, @{ Name = "ModifiedTime"; Expression = { $_.LastWriteTime } }
			foreach ($fileContent in $content)
			{
				Get-ChildItem -Path $fileContent.FullName -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -WhatIf
				Write-Output "$currentTimeStamp | $fileContent deleted." | Out-File -FilePath $logs -Append
			}
		}
		else
		{
			Write-Output "$currentTimeStamp | $userD directory is empty." | Out-File -FilePath $logs -Append
		}
	}
	
	$emptyDirectories = Get-ChildItem -Path $csvFile.Paths -Recurse | Where-Object { ($_.PSIsContainer -eq $True) -and ($_.GetFiles().Count -eq 0) -and ($_.LastWriteTime -lt $older) } | Select-Object @{ Name = "FullName"; Expression = { $_.FullName } }, @{ Name = "ModifiedTime"; Expression = { $_.LastWriteTime } }
	foreach ($eD in $emptyDirectories)
	{
		$emptyDir = $eD.FullName
		Remove-Item -Path $emptyDir -Recurse -Force -WhatIf
		Write-Output "$currentTimeStamp | $eD empty directory deleted." | Out-File -FilePath $logs -Append
	}
}

