# DMicrosoft Defender with detection notification per email using windows event forwarding
Windows Event Forwarding (WEF) is a powerful, integrated log forwarding solution build into Windows operating system. In this case, we will use it to extract and collect logs from windows defender, using simple pull (Collector initiated) method. After triggering a specified event ID, a PowerShell script will be initiated sending us an email. I&#39;m using Windows Server 2016 for collecting and Windows 10 as a client, both located in an AD environment.
 I will also include an option to automate the proces using the Group Policy.

# **1. Client side**

**a. WinRM**

We will start with the client. Open the command prompt as administrator and start the winrm service. This will enable forwarding capabilities in the client system.

```
winrm quickconfig
```

Select yes (y) for both, starting the service and allowing a rule in firewall.

![Screenshot](screens/1.png)


**b. WinRM using GPO**

Here&#39;s a peak at how to set up a GPO for enabling the service.

Computer Configuration \&gt; Preferences \&gt; Control Panel Settings \&gt; Services \&gt; Add

![](RackMultipart20210205-4-z5uggp_html_5fb818d08f233675.png)

Add a new automatic service, from the name section select the WinRM.

![](RackMultipart20210205-4-z5uggp_html_c50dfa2ab90693b4.png)

We also need to add a firewall rule.

Computer Configuration \&gt; Policies \&gt; Windows Settings \&gt; Security Settings \&gt; Windows Firewall with Advanced settings \&gt; Inbound rules \&gt; New rule

Add an allow rule for Windows Remote Management for both public and domain profile.

![](RackMultipart20210205-4-z5uggp_html_c15c0a8912bed3d9.png) ![](RackMultipart20210205-4-z5uggp_html_616184436adef4d9.png)

**c. add Event Log Readers Group**

Next, we need to add the server which is going do collect the events a permission to actually read the events.
 Run computer management as administrator, go to Local Users and Groups \&gt; Groups \&gt; Event log readers

![](RackMultipart20210205-4-z5uggp_html_5f4911dd03e77043.png)

Select Groups \&gt; Event Log Readers \&gt; Add

![](RackMultipart20210205-4-z5uggp_html_5a67d3bfe4b4dd5b.png)

There&#39;s a need to add computers to filtered object types, so we can search for our server.

![](RackMultipart20210205-4-z5uggp_html_7c2c00304fb5956b.png)

**d. add Event Log Readers Group using GPO**

How to automate it? We will use a PowerShell script. Let&#39;s open the PowerShell ISE

![](RackMultipart20210205-4-z5uggp_html_54e4b4e8dbbdb3ce.png)

add-localgroupmember -group &quot;Event Log Readers&quot; -Member &quot;OurDomainName\ServerHostname$&quot;

Save it to  **C:\Windows\SYSVOL\sysvol\OurDomainName\scripts**  on our  **Domain Controller**  so it will be visible for other computers and add a new startup script.

Computer Configuration \&gt; Policies \&gt; Windows Settings \&gt; Scripts \&gt; Startup \&gt; PowerShell Scripts \&gt; Add

![](RackMultipart20210205-4-z5uggp_html_60114b87955d128b.png) ![](RackMultipart20210205-4-z5uggp_html_505017f271bc0a0.png)

# **Server side**

**a. Create Subscription**

Now we will set the server which is going to receive the logs. Open the Event Viewer, go to subscriptions and select &#39;yes&#39; in the prompt as we want the service to be automatically started.

![](RackMultipart20210205-4-z5uggp_html_9658941433a66cda.png)

Create a new Subscription:

![](RackMultipart20210205-4-z5uggp_html_e80c2583025efc1f.png)

In Advanced select Minimize Latency to reduce the [delivery to 30 seconds ](https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection#how-frequently-are-wef-events-delivered)

![](RackMultipart20210205-4-z5uggp_html_bab410b5801bcdc3.png)

In this proof of concept, we want to receive only logs from Microsoft Defender.
 Select events \&gt; XML \&gt; and &quot;yes&quot; and paste the following XML

\&lt;QueryList\&gt;

\&lt;Query Id=&quot;0&quot; Path=&quot;Microsoft-Windows-Windows Defender/Operational&quot;\&gt;

\&lt;Select Path=&quot;Microsoft-Windows-Windows Defender/Operational&quot;\&gt;\*\&lt;/Select\&gt;

\&lt;/Query\&gt;

\&lt;/QueryList\&gt;

![](RackMultipart20210205-4-z5uggp_html_d133fc6518747d14.png)

After that we can connect our client in Select Computers \&gt; Add Domain Computers. We can also test the connection after adding.

![](RackMultipart20210205-4-z5uggp_html_f9a96c71cc65cff.png)

**b. Email notification**

Last but not least, we will use Task Schleuder to trigger a PowerShell script sending us a notification email.

Set the account to SYSTEM and select to Run with highest privileges.

![](RackMultipart20210205-4-z5uggp_html_196b6114253694bb.png)

We will select the triggering based on [Microsoft IDs base](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-antivirus/troubleshoot-microsoft-defender-antivirus). Note, that there are two IDs we are interested in – 1006 and 1116. We can only paste one so there will be a need for two Tasks.

![](RackMultipart20210205-4-z5uggp_html_40527a702d84798d.png)

Before creating an action, we need to set up our email script.

![](RackMultipart20210205-4-z5uggp_html_1a3e7a8157f9233a.png)

$Username = &quot;username - our email in google&quot;;

$Password = &quot;password&quot;;

function Send-ToEmail([string]$email, [string]$attachmentpath){

$message = new-object Net.Mail.MailMessage;

$message.From = &quot;from&quot;;

$message.To.Add($email);

$message.Subject = &quot;Malware Detected on a host!&quot;;

$message.Body = &quot;Please review the forwarded Event Viever&quot;;

$smtp = new-object Net.Mail.SmtpClient(&quot;smtp.gmail.com&quot;, &quot;587&quot;);

$smtp.EnableSSL = $true;

$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);

$smtp.send($message);

write-host &quot;Mail Sent&quot; ;

}

Send-ToEmail -email &quot;paste the receiver email here&quot;;

#Send-ToEmail -email &quot;if you want, we can add a second receiver in the next line&quot;;

Let&#39;s save it and go back to our Event Schleuder in the Actions tab.

![](RackMultipart20210205-4-z5uggp_html_6d79764bc2e31d57.png)

Program should be set to &#39; **powershell**&#39; and in the Argument section paste the path to your saved script

-File C:\PATH-to-the-previous-powershell-script.ps1

Deselect the AC power option in Conditions tab

![](RackMultipart20210205-4-z5uggp_html_464d6338259948d5.png)

And set to run new instance in paralel in settings tab

![](RackMultipart20210205-4-z5uggp_html_42cf8bb5ad077eb6.png)

Now do the same for the second malware found ID – 1116

![](RackMultipart20210205-4-z5uggp_html_e759356021d9c1b3.png)

# **Testing**

Let&#39;s check the connection again, this time we will be using Runtime status. You will use it many times in the future to troubleshoot issues. Everything&#39;s looking alright.

![](RackMultipart20210205-4-z5uggp_html_7fa09bfca80c7949.png)

No let&#39;s check the forwarded Event&#39;s tab.
Looks good!

![](RackMultipart20210205-4-z5uggp_html_c6b32e8729a95181.png)

There will be a lot of logs we&#39;re not interested in like a successful definition update, schleuded scan notification etc.
 There&#39;s a need for creating a custom view to filter out the noise.

Select the &#39;create custom view&#39; option

![](RackMultipart20210205-4-z5uggp_html_7bf38d20555e16c.png)

And let&#39;s concentrate only on our two &#39;malware found&#39; IDs.

![](RackMultipart20210205-4-z5uggp_html_a62e27ee06cbc9e2.png)

Let&#39;s try it out! Use the Eicar test file which is used to test anti malware software at eicar.org

Download the zip file and open it. You can safely ignore the SmartScreen warning in this case.

![](RackMultipart20210205-4-z5uggp_html_a014182844311235.png)

We triggered a detection!

![](RackMultipart20210205-4-z5uggp_html_6cb600ac4999f634.png)

And here are our results (In Polish as I needed to change the language :D)

![](RackMultipart20210205-4-z5uggp_html_670fd0eef299e171.png)

We also received an email!

![](RackMultipart20210205-4-z5uggp_html_a66057a63789e662.png)

# **Conclusion**

The method won&#39;t ever replace a proper managed AV or EDR solution but it&#39;s really fun to make, cost nothing if you&#39;re already using an AD and gives us a little bit of information at what&#39;s going on when we are on a tight tools budget 🙂

# **Resources**

[https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection#how-frequently-are-wef-events-delivered](https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection#how-frequently-are-wef-events-delivered)

[https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-antivirus/troubleshoot-microsoft-defender-antivirus](https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-antivirus/troubleshoot-microsoft-defender-antivirus)
