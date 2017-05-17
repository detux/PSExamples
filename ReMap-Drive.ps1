<#
	.NOTES
	===========================================================================
	 Created on:   	29/12/2016 10:58 AM
	 Created by:   	<author>
	 Organization: 	<company>
	 Filename:     	ReMap-Drive.ps1
	===========================================================================
	
	.DESCRIPTION
    		The user can select the CSV file from the "WhatAreMySharedDrives" 
		folder based on the date last created and the drives will be 
		remapped.
	
	.EXAMPLE
		./ReMap-Drive.ps1
#>

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
Clear-Host
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$myDocuments = [environment]::getfolderpath("mydocuments")

##############################################################################
#.SYNOPSIS
# Reads the CSV files and performs the mapping.
#
#.DESCRIPTION
# Reads the CSV files and checks if the drive letter is already mapped if not
# maps the drive letter and informs the user of the mapped drives. If no mapping
# is required, another message informs the user of the same.
#
#.PARAMETER fileCSV
# Calculates the number of days before the password was set to expoire.
##############################################################################
Function reMapDrives($fileCSV)
{
    $Network = New-Object -ComObject "Wscript.Network"
    $fileCSVDetails = Import-Csv $fileCSV
    $count = 0
    $array = @()
    $driveLetter

    foreach($fCSV in $fileCSVDetails)
    {
        if((Test-Path $fCSV.DL) -eq $True)
        {
            $count = $count + 1
            $array += $fCSV.DL
        }
        else
        {
            try
            {
                $Network.MapNetworkDrive($fCSV.DL,$fCSV.NP,$True)
                $driveLetterMapped = $fCSV.DL
		        [System.Windows.Forms.MessageBox]::Show("Please check MY COMPUTER to see your mapped drive, $driveLetterMapped", "My Shared Drives")
            }
            catch
            {
                $driveLetterNMapped = $fCSV.DL
                [System.Windows.Forms.MessageBox]::Show("An error has occured mapping your drive $driveLetterNMapped, Please contact HelpDesk on x7500 for assistance.", "My Shared Drives")
            }
        } 
    }
    if($count -ge 1)
    {
        [String]::Join('',$array)
        [System.Windows.Forms.MessageBox]::Show("$count drives $array have not changed since it was last mapped", "My Shared Drives")
    }
}

##############################################################################
#.SYNOPSIS
# Displays the Open Window to the user.
#
#.DESCRIPTION
# The Open Window is displayed showing the list of all the CSV files. The 
# user selects the files in question and clicks Open.
#
#.PARAMETER initialDirectory
# Location of the file containing the CSV files.
##############################################################################
Function Get-FileName($initialDirectory)
{   
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowHelp = $true
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$fileDetails = Get-FileName -initialDirectory $myDocuments"\WhatAreMySharedDrives"
remapDrives $fileDetails
Stop-Process -Name "Powershell"
