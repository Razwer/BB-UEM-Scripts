# Initial script by Rob Hager
# Improved by Yoni Toorenspits


### Global Variables ###
    $global:tenant = "s73711005" ### enter SRP 
    $global:admin = "admin"
    $pass = "foobar"
    $global:servers = "uemga02.gdbeslab.com"
    $global:WebServicesPort = "18084"

    #don't edit this
    $pass  = [System.Text.Encoding]::UTF8.GetBytes("$pass") 
    $global:password = [System.Convert]::ToBase64String($pass)


# Disable SSL verification ($true = disabled, $false = enabled)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

function uemSetServer { ### ensures UEM service is "up and running"

    foreach ($server in $servers){
        $serverCheck = $null
        $URL = "https://"+"$server"+":18084/"+"$tenant"+"/api/v1/util/ping"
        $serverCheck = Invoke-RestMethod  -Uri $url
        if ($serverCheck -like "Up and running*") {
            $global:server = $server
            return
            }
        }
 }

## Construct rest base url
uemSetServer
$RestBaseUrl = "https://"+"$server"+":18084/"+"$tenant"

 function uemAuthHeader {
    uemSetServer
    $URL = $RestBaseUrl+"/api/v1/util/authorization"
    $contentType = "application/vnd.blackberry.authorizationrequest-v1+json"
    $body = "{
    `"provider`" : `"LOCAL`",
    `"username`" : `"$admin`", 
    `"password`" : `"$password`"}"
    Write-Host $body -ForegroundColor Green
    $resp = Invoke-RestMethod -Uri $URL -ContentType $contentType -Body $body -Method Post
    $global:auth = $resp
 }

  function uemGetGroups {
    if(!$auth) {uemAuthHeader}
    uemSetServer
    $URL = $RestBaseUrl+"/api/v1/groups"
    $Headers = @{'Accept'= 'application/vnd.blackberry.groups-v1+json' ;'Authorization'="$auth"}
    Invoke-RestMethod  -Uri $URL -Headers $Headers -Method GET
 }

  function uemGetUserGUID {
    param ($username)
    uemSetServer
    if(!$auth) {uemAuthHeader}
    $URL = $RestBaseUrl+"/api/v1/users?query=username="+$username
    $Headers = @{'Authorization'="$auth"}
    #$resp = Invoke-WebRequest  -Uri $URL -Headers $Headers
    $resp = Invoke-RestMethod  -Uri $URL -Headers $Headers  -Method get
    $userguid = $resp.users.guid
    return $userguid
 }

  function uemSetActivationPassword {
    param (
        $username,
        $actPassword
        )
    uemSetServer
    if (!$username) { return }
    if (!$actPassword){ $actPassword = "blackberry" }
    $b  = [System.Text.Encoding]::UTF8.GetBytes("$actPassword")
    $actPassword = [System.Convert]::ToBase64String($b)
    $expires = Get-Date (Get-Date).AddDays(29) -format yyyy-MM-ddThh:mm:ss-05:00
    $userGUID = uemGetUserGUID -username $username
    if(!$auth) {uemAuthHeader}
    $URL = $RestBaseUrl+"/api/v1/users/"+$userGuid+"/activationPasswords"
    $contentType = "application/vnd.blackberry.activationpasswords-v1+json"
    $Headers = @{'Authorization'="$auth"}
    $body = "{
        `"activationPasswords`" : [ {
            `"password`" : `"$actPassword`",
            `"expiry`" : `"$expires`",
            `"expireAfterUse`" : `"false`"
            } ] }"
  
    Invoke-RestMethod -ContentType $contentType -Uri $URL -Headers $Headers -Method put  -Body $body 
   
 }