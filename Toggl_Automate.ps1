#Automate Timesheets
#Manually Adjust your date range below. Will skip weekends but not holdays, keep that in mind. 
#Grab your API key from toggl.com, will prompt on run. 

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$APIKEY = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Toggl API Key", "APIKEY", "")

#Toggl API Config
$pair = $APIKEY+ ':api_token'

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}



#Time Loop
$startdate = Get-Date -Date '2016-09-01'
$enddate = Get-Date -Date '2016-09-30'

$difference = New-TimeSpan -Start $startdate -End $enddate
#$difference.Days

$days = [Math]::Ceiling($difference.TotalDays)+1

 $workingDays = 1..$days | ForEach-Object {
 $startdate
  $startdate = $startdate.AddDays(1)
} | Where-Object { $_.DayOfWeek -gt 0 -and $_.DayOfWeek -lt 6}
  
  
  
  Foreach($WorkingDay in $workingDays)
{
$DateToCreate = $WorkingDay.tostring("yyyy-MM-dd")
$DateToCreate
#$postParams = '{"time_entry":{"description":"API Test","duration":28800,"start":"2015-$Month-$DayT09:00:00.000Z","created_with":"curl"}}'
$postParams = '{"time_entry":{"description":"Support Work","duration":28800,"start":"'+ $DateToCreate + 'T13:00:00.000Z","pid":9040069,"created_with":"PowerShell"}}'
Invoke-WebRequest -Uri 'https://www.toggl.com/api/v8/time_entries' -Headers $Headers -ContentType "application/json" -Method Post -Body $postParams
}
    












