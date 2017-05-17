<#
	.NOTES
	===========================================================================
	 Created on:   	12/02/2017 02:15 PM
	 Created by:   	<author>
	 Organization: 	<company>
	 Filename:     	Import-RootCertificate.ps1
	===========================================================================
	
  	.DESCRIPTION
  		Imports the certificates from the directory with the ".der" extension. The
  		certificates are imported into the Trusted Root store of the local machine.
  		This script is run locally on the users machine with local admin rights.
  		Right-Click Run the powershell console as "As Administrator".
  
  	.EXAMPLE
  		./Import-RootCertificate.ps1
#>

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$Path = $scriptDir+"\certsRoot\"
$Filetype = ".der"

# Read in files and set up counter
$certFile = get-childitem $Path | where {$_.Extension -match $Filetype}
$i = 0

# Import Loop
foreach ($cert in $certFile)
    {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.import($Path + $certfile.Name[$i])
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
        $store.Open("MaxAllowed") 
        $store.Add($cert) 
        $store.Close()
        Write-Host "Certificate" $certfile.Name[$i] "- IMPORTED SUCCESSFULLY!"
        $i++ 
             
    }

Write-Host "--- Sucessfully imported: $i Certificates"
Read-Host "Press any key to continue..."
