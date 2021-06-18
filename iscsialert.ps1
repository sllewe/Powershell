<#
    .SYNOPSIS
        Brute force method to resolve iscsi dismounts
    .DESCRIPTION
        To be run under Task Scheduler on boot
    .Parameters
        n.a
#>


Function SendEmail
{
	$Username = $EmailUN
	$Password = $PW
	$credential = New-Object System.Management.Automation.PSCredential $Username, $Password
	$SMTPServer = "smtp.office365.com"
	$EmailFrom = $EmailUN

#$Body = "iSCSi Vol"
[string[]]$EmailTo = $Email


	Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailUN -to $EmailTo -subject $Subject -Body $Body  -BodyAsHtml -Attachments $logpath
}


$date = Get-Date -Format yyyy-MM-dd-HH-mm
$canarydate = (Get-Date).Day
$logpath = 'C:\temp\iscsicheck' + $date + '.txt'
Write-Output 'Starting iSCSICheck' | Out-File -FilePath $logpath -Append 


$isconnected = Get-IscsiConnection
    if ($isconnected -ne $null) 
        {Write-Output 'Iscsi is connected, ignoring' | Out-File -FilePath $logpath -Append}

    if ($isconnected -eq $null)
        {
            Write-Output 'Iscsi has been detected as down, triggering reconnect' | Out-File -FilePath $logpath -Append 
            $iscitarget = Get-IscsiTarget
            Connect-IscsiTarget -NodeAddress $iscitarget.NodeAddress -IsPersistent $true
            $afterconnect = Get-IscsiConnection

            if ($afterconnect -ne $null)
                {
                    Write-Output 'Iscsi has been reconnected...done' | Out-File -FilePath $logpath -Append 
                    $Subject = "iSCSI Alert: Drive Has Been Reconnected"
                    $Body = 'No further action required, see attachement for more info'
                    SendEmail
                }
            if ($afterconnect -eq $null)
                {
                    $Subject = "iSCSI Alert: Attempt to reconnect failed"
                    $Body = 'Please Investigate'
                    SendEmail
                }

        }

if ($canarydate -eq '25') 
    {
        $Subject = "Monthly Health Check of iSCSI Script"
        $Body = 'This email indicates that the script is running daily as it should. Attached is the most recent logfile.'
        $logpath = (gci C:\xpercare\scriptlogs | sort LastWriteTime | select -last 1).fullname
        SendEmail
    }
