$mcreden = New-Object System.Net.NetworkCredential($Username, $Password); 
$Username = "oltpdba@gmail.com";
$Password= "1800Oltpdba/";

Send-MailMessage -SmtpServer "smtp.gmail.com" -Port 587 -UseSsl -From "Dr.Nefario <oltpdba@gmail.com>" -To "oltpdba@gmail.com" -Subject "SQL NOT running on preferred node" -Credential "oltpdba@gmail.com"