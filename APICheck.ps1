###Pulls config info from CMDB
###Script Will not run overnight
###Checks for valid HTTP Response, Creates exectption and captures output to be sent via email if response is different. 


#THis function simply allows easy SQL Calls from powerhsell. Be careful this will run WHATEVER you include in the statment. 
#Example call (RunSQL "DBServer\instance" "DBNAME" "SQL Query") 
 Function RunSQL ($sqlsrv, $dbName, $dbQuery)
{
$SQLServer = "$sqlsrv" #use Server\Instance for named SQL instances!
$SQLDBName = "$dbName"
$SqlQuery = "$dbQuery"
 
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True;"
$SqlConnection.FireInfoMessageEventOnUserErrors=$true
$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-output "$($_)"}
$Sqlconnection.add_InfoMessage($handler)
 
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
 
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
 
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
 
$SqlConnection.Close()

$DataSet.Tables[0]
 }

 

$currenttime = Get-Date -Format HH


$postParams = @{
# Put your parameters here. 
}


$expectedresponse = '200'

$checkurl = '/api/'
# SQL Statement assigned to object$GetSite = ()


#Get exactly what data is needed. 
$CheckIP = $GetSite.IPAddress

Write-Output "Current time is" $currenttime

if($currenttime -le 20 -or $currenttime -le 5) #This allows you to change when the check happens.

{

Write-Output "Performing site check for all servers with the siteID of $siteID" 


foreach ($IP in $CheckIP) 
{

$FinalIP = $IP + $checkurl

try{


 $response = (Invoke-WebRequest $FinalIP -Method Post -Body $postParams -TimeoutSec 5 -UseBasicParsing).StatusCode  
 }
 catch {

 Write-Output "Node down at $FinalIP"
$ExceptionError =  $_.Exception.Response.StatusCode.Value__ 

 }
 if ($response -eq $expectedresponse)

 {
Write-Output "No issues found For $FinalIP"

 }

 else {
 Write-Output "Failure Found - Checking again"
 Start-Sleep -s 30


 try {
  $secondresponse = (Invoke-WebRequest $FinalIP -Method Post -Body $postParams -TimeoutSec 5 -UseBasicParsing).StatusCode

  }
  catch {

   Write-Output "Node down at $FinalIP"

  }
   if ($secondresponse -eq $expectedresponse)
   {
   Write-Output  "No issues found"

   }
   else 

   {

  

 $body = "<HTML><HEAD><META http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" /><TITLE></TITLE></HEAD>"
	$body += "<BODY bgcolor=""#FFFFFF"" style=""font-size: Large; font-family: TAHOMA; color: #000000""><P>"
 $body += " <font color=red>API down at node: $IP With http error: $ExceptionError</font> <br>"
 send-mailmessage #Youremail@email.com "API NODE: $IP Down" -bodyashtml -body $body -from  -SmtpServer 

   }

 }

 }

 }

 else 
 {
Write-Output "Currently in maintenance window" 
 } 