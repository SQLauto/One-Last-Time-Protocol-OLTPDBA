#############################################################################
$emailSmtpServer = "smtp.gmail.com"
$emailSmtpServerPort = "587"
$emailSmtpUser = "oltpdba@gmail.com"
$emailSmtpPass = "1800Oltpdba/"
 
$emailMessage = New-Object System.Net.Mail.MailMessage
$emailMessage.From = "OLTPDBA <oltpdba@gmail.com>"
$emailMessage.To.Add( "oltpdba@gmail.com" )
$emailMessage.Subject = "PS Mail"
#$emailMessage.IsBodyHtml = $true
$emailMessage.Body = @"
Hello there!!!
"@
 

#attachments
#$attachment = "C:\myfile.txt"
#$emailMessage.Attachments.Add( $attachment)

$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $true

#credentials
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );
 
 #Send mail
$SMTPClient.Send( $emailMessage )
##############################################################################

<#$Username = "oltpdba@gmail.com";
$Password= "1800Oltpdba/";#>





