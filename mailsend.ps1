$Username = "username - our email in google";
$Password = "password";

function Send-ToEmail([string]$email, [string]$attachmentpath){

    $message = new-object Net.Mail.MailMessage;
    $message.From = "from";
    $message.To.Add($email);
    $message.Subject = "Malware Detected on a host!";
    $message.Body = "Please review the forwarded Event Viever";

    $smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", "587");
    $smtp.EnableSSL = $true;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
    $smtp.send($message);
    write-host "Mail Sent" ;
 }
Send-ToEmail  -email "paste the receiver email here";
#Send-ToEmail  -email "if you want, we can add a second receiver in the next line";