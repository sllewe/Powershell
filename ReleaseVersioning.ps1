#Take in $buildnumber and set as html page at $deployedserverlocation

Param([Parameter(Mandatory=$true)][string]$buildnumber, [string]$deployserver, [string]$environmentmessage, [string]$deployedserverlocation)

$statuspage  = @"
<body> <h1> $environmentmessage </h1> <p> Build Number $buildnumber </p> <br> <p> Deployed from $deployserver </p> </body>  </body>
"@
 
 
 $statuspage | ConvertTo-Html -body $statuspage | out-file $deployedserverlocation