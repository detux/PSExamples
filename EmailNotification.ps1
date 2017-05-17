<#
	.NOTES
	===========================================================================
	 Created on:   	2/5/2015 11:00 AM
	 Created by:   	<author>
	 Organization: 	<company>
	 Filename:     	EmailNotification.ps1
	===========================================================================
	.DESCRIPTION
	The script sends out pre-notification alert emails 7 and 2 days before 
	the passwords are set to expire.
#>

$userEmailAddresses = Get-Content "<location path to email text> "
$firstExpiryAlert = 7
$secondExpiryAlert = 2

##############################################################################
#.SYNOPSIS
# Sends email to the users notfying them of the expiry of the windows password
#
#.DESCRIPTION
# Email is sent to the users based with the customized HTML code embedded in 
# the script.
#
#.PARAMETER days_remaining
# Calculates the number of days before the password was set to expoire.
#
#.PARAMETER email
# The email address of the user.
#
#.PARAMETER User_name
# Domain account of the user.
##############################################################################
function send_email ($days_remaining, $email, $User_name) 
{
 $smtpServer1 = "<smtp server>"
 $smtp1 = new-object system.net.mail.smtpClient($smtpServer1)
 $msg1 = New-Object system.net.mail.mailmessage 
 $msg1.From = "<sender email address>"
 $msg1.To.Add($email)
 $msg1.Subject = "Your password is due to expire"
 $msg1.IsBodyHtml = $true
 $msg1.Body = @("
 <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
<html xmlns='http://www.w3.org/1999/xhtml' xmlns:m='http://schemas.microsoft.com/office/2004/12/omml' xmlns:v='urn:schemas-microsoft-com:vml' xmlns:o='urn:schemas-microsoft-com:office:office'>

<head>
<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />
    <title>Password Expiring</title>
    <style type='text/css'> 
        body {font-family: Arial, Helvetica, sans-serif; font-size: small; color: black }
        a:link {color:blue;text-decoration:underline;text-underline:single;}
        .titleRed{ font-weight: bolder; color: red}
        .subTitleBold{ font-weight: bold;}
        .noteRed{ font-size: x-small; font-weight: bolder; color: red}                                               
    </style>
</head>
<body>
    <p class='titleRed'>Attention: Your password will expire in $days_remaining days.</p>
    <p>To change your password must be connected to the company network, either in the office or via VPN.<br> 
        Press Ctrl + Alt + Delete at the same time and select the Change Password button.<br>
        In the username field enter <span style='color: red'><domain>\$User_name</span><br>
        In the old password field, enter your current password.<br>
        In the new password and confirm password fields, enter a new password.</p>
    <p>Your password needs to follow certain complexity requirements. The password must:</p>

    <ul>
        <li>Be at least 8 characters long (If you have <b><u>permanent administration rights</u></b>, your password needs to be at least 15 characters long.)</li>
        <li>Contain at least 1 upper case, 1 lower case letter, 1 number and 1 special symbol e.g. @!(#_</li>
        <li>Not include your name</li>
        <li>Not be any of your previous 8 passwords</li>
    </ul> 
    
    <p>For your convenience, you may wish to match your Windows password and your Email password<br>
    <span class='noteRed'>Please note that this is optional; Information Security recommends having a separate password for each application.</span> 
    <p>If you have a business iPhone/iPad that receives email, you will need to update your password on your device as follows: Settings -> Mail, Contacts, Calendars -> Exchange -> Account, then select the password field and type in your new password.
    </p>
</p>
<p>
Regards,<br>
<br>
Service Delivery Manager<br>
</p>
</body>
</html>
")
$smtp1.Send($msg1) 
}

##############################################################################
#.SYNOPSIS
# Checks the NUMBER of days before the password is set to expire as well as
# the SamAccountName of the domain user. 
#
#.DESCRIPTION
# Based on the email address of the user, the date of expiry of the password 
# as well as the SamAccountName of the user is captured. The datetoPasswordExpiry
# object is comapared with the alert thresholds and if there is a match, an 
# email is sent notfying of the same.
##############################################################################
function passwordExp 
{    
    foreach($userUPN in $userEmailAddresses)
    {
        try
        { 
            if($userUPN -like "*@<company FQDN>")
            {
                $daysToPasswordExpiry = (([datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(userprincipalname=$userUPN) (!(useraccountcontrol:1.2.840.113556.1.4.803:=2)))" -Server <domain> -Properties "msDS-UserPasswordExpiryTimeComputed")."msDS-UserPasswordExpiryTimeComputed"))-(Get-Date)).Days
                $userName = Get-ADUser -LDAPFilter "(&(userprincipalname=$userUPN) (!(useraccountcontrol:1.2.840.113556.1.4.803:=2)))" -Server <domain> | Select -ExpandProperty SamAccountName
                
                if($userName -ne $null)
                {   
                    if($daysToPasswordExpiry -eq $firstExpiryAlert)
                    {
                        Write-Host -ForegroundColor Green -BackgroundColor Black $userUPN password will expire in $daysToPasswordExpiry days
                        send_email $daysToPasswordExpiry $userUPN $userName
                    }
                    elseif($daysToPasswordExpiry -eq $secondExpiryAlert)
                    {
                        Write-Host -ForegroundColor Yellow -BackgroundColor Black $userUPN password will expire in $daysToPasswordExpiry days
                        send_email $daysToPasswordExpiry $userUPN $userName
                    }
                }
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message $ErrorMessage 
        }
    }
}
passwordExp
