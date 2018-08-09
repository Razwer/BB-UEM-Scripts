###################################################
# GC Powershell to Soap Translator                #
# Created by Yoni Toorenspits                     #
# Inspiration and Soap code by Keith Schutte      #
# Special Thanks to Johan Eikelenboom for PS tips #
#                                                 #
# Version 1.2                                     #
# Released Jan 5th 2016                           #
# Revised April 29th 2016                         #
#                                                 #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2016 Yoni Toorenspits, Keith Schutte and Johan Eikelenboom                                                         #
#######################################################################################################################


# Set vars
$GCHost = "mygc.domain.local" # The GC host to target for SOAP calls
$GoodServiceAcct = "domain\myuser" # Username for GC
$GoodServiceAcctPW = "MyPass!"# Password for GC user

# Disable SSL verification ($true = disabled, $false = enabled)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Setting the powershell user for audit purposes in GC
$WhoDidThis = "PowerShell\"+[Environment]::UserName+$GoodServiceAcct

## Functions

# Soap Execution function
function Execute-SOAPRequest 
( 
        [Xml]    $SOAPRequest, 
        [String] $URL,
        [String] $SoapCommandFunction 
) 
{ 
        # Check for GC or CAP
        if (!$cap) { 
            $url = 'https://'+$GCHost+'/gc/services/GCService' 
            $urn = "urn:gc10.good.com"
        } else { 
            $url = 'https://'+$GCHost+'/gc/soapproxy/cap' 
            $urn = "urn:cap11.good.com"
            
        }
        
        #write-host "Sending SOAP Request To Server: $URL" 
        # Build headers and send Soap request
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
        $soapWebRequest.Headers.Add("SOAPAction",$urn+':gcServer:'+$SoapCommandFunction)
        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        #write-host "Initiating Send." 
        # Initiating Send
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
        #write-host "Send Complete, Waiting For Response." 
        # Wait for Response
        $resp = $soapWebRequest.GetResponse() 
        $responseStream = $resp.GetResponseStream() 
        $soapReader = [System.IO.StreamReader]($responseStream) 
        $ReturnXml = $soapReader.ReadToEnd() 
		
		if ($ReturnXml.Contains("Content-Type: application/xop+xml" ))
        {
			$tempstr = $ReturnXML.Substring($ReturnXML.Indexof("<?xml version='1.0'"),$ReturnXML.Indexof("</soapenv:Envelope>")-$ReturnXML.Indexof("<?xml version='1.0'")+19);
			#write-host $tempstr
			$ReturnXML =[XML]$tempstr
        }
		
        $responseStream.Close() 
        
        #write-host "Response Received."
        return $ReturnXml 
}

# Building Soap envelope to send to Soap Execution function. Limited to 3 input values.
function Build-Envelope 
( 
        [String] $SoapCommand,
        [String] $SoapInput,
        [String] $SoapInputValue,
        [string] $SoapInput2,
        [string] $SoapInput2Value,
        [string] $SoapInput3,
        [string] $SoapInput3Value 
) 
{ 
    # Build XML 
    
    # Check for GC or CAP SOAP
    if (!$cap) { $urn = "urn:gc10.good.com" } else { $urn = "urn:cap11.good.com" }

    # Build String input if exists
    if ($SoapInput) { $SoapInputXML =  "<urn:$SoapInput>$SoapInputValue</urn:$SoapInput>" }
    if ($SoapInput2) { $SoapInput2XML =  "<urn:$SoapInput2>$SoapInput2Value</urn:$SoapInput2>" }
    if ($SoapInput3) { $SoapInput3XML =  "<urn:$SoapInput3>$SoapInput3Value</urn:$SoapInput3>" }
            
    # Setting WSSE security and credentials
    $tempsoap = '<?xml version="1.0" ?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><wsse:UsernameToken wsu:Id="UsernameToken-10" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><wsse:Username>'
    $tempsoap += $GoodServiceAcct
    $tempsoap += '</wsse:Username><wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'
    $tempsoap += $GoodServiceAcctPW
    # Build Envelope
    $tempsoap += '</wsse:Password></wsse:UsernameToken></wsse:Security></soapenv:Header><soapenv:Body><urn:'+$SoapCommand+' xmlns:urn="'+$urn+'">'
    $tempsoap += $SoapInputXML+$SoapInput2XML+$SoapInput3XML+'</urn:'+$SoapCommand+'></soapenv:Body></soapenv:Envelope>'

    
    # Complete XML
    $soap = [XML]$tempsoap
    #Return value
    return $Soap
}


# Same as above but no sub xml
function Build-EnvelopeSingleSub
( 
        [String] $SoapCommand,
        [String] $Subname,
        [String] $SoapInput1,
        [String] $SoapInputValue1,
        [string] $SoapInput2,
        [string] $SoapInput2Value,
        [string] $SoapInput3,
        [string] $SoapInput3Value, 
        [string] $SoapInput4,
        [string] $SoapInput4Value, 
        [string] $SoapInput5,
        [string] $SoapInput5Value,
        [string] $SoapInput6,
        [string] $SoapInput6Value 
) 
{ 
    # Build XML 
    
    # Check for GC or CAP SOAP
    if (!$cap) { $urn = "urn:gc10.good.com" } else { $urn = "urn:cap11.good.com" }

    # Build String input if exists
    if ($SoapInput1) { $SoapInput1XML =  "<urn:$SoapInput1>$SoapInputValue1</urn:$SoapInput1>" }
    if ($SoapInput2) { $SoapInput2XML =  "<urn:$SoapInput2>$SoapInput2Value</urn:$SoapInput2>" }
    if ($SoapInput3) { $SoapInput3XML =  "<urn:$SoapInput3>$SoapInput3Value</urn:$SoapInput3>" }
    if ($SoapInput4) { $SoapInput4XML =  "<urn:$SoapInput4>$SoapInput4Value</urn:$SoapInput4>" }
    if ($SoapInput5) { $SoapInput5XML =  "<urn:$SoapInput5>$SoapInput5Value</urn:$SoapInput5>" }
    if ($SoapInput6) { $SoapInput6XML =  "<urn:$SoapInput6>$SoapInput6Value</urn:$SoapInput6>" }
            
    # Setting WSSE security and credentials
    $tempsoap = '<?xml version="1.0" ?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><wsse:UsernameToken wsu:Id="UsernameToken-10" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><wsse:Username>'
    $tempsoap += $GoodServiceAcct
    $tempsoap += '</wsse:Username><wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">'
    $tempsoap += $GoodServiceAcctPW
    # Build Envelope
    $tempsoap += '</wsse:Password></wsse:UsernameToken></wsse:Security></soapenv:Header><soapenv:Body><urn:'+$SoapCommand+' xmlns:urn="'+$urn+'">'
    $tempsoap += '<urn:'+$subname+'>'+$SoapInput1XML+$SoapInput2XML+$SoapInput3XML+$SoapInput4XML+$SoapInput5XML+$SoapInput6XML+'</urn:'+$subname+'>'+'</urn:'+$SoapCommand+'></soapenv:Body></soapenv:Envelope>'
    

    # Complete XML
    $soap = [XML]$tempsoap
    #Return value
    return $Soap
    
}

# Fetch user id function. Input must be matching email address.
function Get-Userid
( 
        [String] $EmailInput
) 
{
    $GetUserEnvelope = (Build-Envelope "GetUserRequest" "stringId" $emailInput)
    $GetUserIdRequest = (Execute-SOAPRequest $GetUserEnvelope $url)
    [string]$UserId = $GetUserIdRequest.Envelope.Body.GetUserResponse.user.userId
    return $UserId
}

# Fetch accesskeys based on user id input. Output xml
function Get-Accesskey
( 
        [String] $UserIdInput
) 
{
    $GetAccesskeyEnvelope = (Build-Envelope "GetAccessKeysRequest" "userId" $UserIdInput)
    $GetAccesskeyRequest = (Execute-SOAPRequest $GetAccesskeyEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetAccesskeyRequest = $GetAccesskeyRequest
    $GetAccesskey = $GetAccesskeyRequest.Envelope.Body.GetAccessKeysResponse.containerList
    return $GetAccesskey
}

# Generate Access key based on user id input. Second param is for key amount. If none entered, only generate 1.
function Generate-Accesskey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="User ID must be entered. use Get-UserId to translate email to user ID")]
        [Alias('id')]
        [String] $UserId,
        [Parameter(Mandatory=$False,
            ValueFromPipeline=$False,
            ValueFromPipelineByPropertyName=$False,
            HelpMessage="Enter amount of keys if more than 1 is required")]
        [String] $Amount = "1"
    )
    BEGIN {}
    PROCESS {
        foreach ($UserIdInput in $UserId) {
            $GenerateAccesskeyEnvelope = (Build-Envelope "GenerateAccessKeysRequest" "userId" $UserIdInput "num" $Amount)
            $GenerateAccesskeyRequest = (Execute-SOAPRequest $GenerateAccesskeyEnvelope $url)
            [xml]$GenerateAccesskeyRequest = $GenerateAccesskeyRequest
            $GenerateAccesskey = $GenerateAccesskeyRequest.Envelope.Body.GenerateAccessKeysResponse.containerList
            return $GenerateAccesskey
            write-host $GenerateAccesskey
            }
        }
    END {}
}

# Fetch application groups for user based on user id. Output is xml
function Get-GroupsForUser
( 
        [String] $UserId
) 
{
    # Set Cap for CAP SOAP, not GC
    $cap = "true"
    $GetGroupsForUserEnvelope = (Build-Envelope "getGroupsForUserRequest" "user_id" $userid)
    $GetGroupsForUserRequest = (Execute-SOAPRequest $GetGroupsForUserEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetGroupsForUserRequest = $GetGroupsForUserRequest
    $GetGroupsForUser = $GetGroupsForUserRequest.Envelope.Body.getGroupsForUserResponse.groups.group
    return $GetGroupsForUser
}

function Get-AllPolicies {
    
    # Get all GC policies
    $GetAllPoliciesEnvelope = (Build-Envelope "GetAllPoliciesRequest")
    $GetAllPoliciesRequest = (Execute-SOAPRequest $GetAllPoliciesEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetAllPoliciesRequest = $GetAllPoliciesRequest
    $GetAllPolicies = $GetAllPoliciesRequest.Envelope.Body.GetAllPoliciesResponse.policyList
    return $GetAllPolicies
}

# **WIP** Function for all policy settings to XML. **XML NEEDS CLEANUP**
function Get-PolicyDetail 
( 
        [String] $policySetId
) 
{
    # Get Details of polcies. Requires policy id input. Use get-allpolicies command to distill
    $GetPolicyDetailEnvelope = (Build-Envelope "GetPolicyDetailRequest" "policySetId" $policySetId)
    $GetPolicyDetailRequest = (Execute-SOAPRequest $GetPolicyDetailEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetPolicyDetailRequest = $GetPolicyDetailRequest
    $GetPolicyDetail = $GetPolicyDetailRequest.Envelope.Body.GetPolicyDetailResponse.policyDetail
    return $GetPolicyDetail
}

# Get all properties from the GC you query. For audit purposes.
function Get-GCProperties {
    
    # Get all GC policies
    $GetGCPropertiesEnvelope = (Build-Envelope "GetGCPropertiesRequest")
    $GetGCPropertiesRequest = (Execute-SOAPRequest $GetGCPropertiesEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetGCPropertiesRequest = $GetGCPropertiesRequest
    $GetGCProperties = ($GetGCPropertiesRequest.Envelope.Body.GetGCPropertiesResponse.properties | select key,value)
    return $GetGCProperties
}

# Fix the pin output to the same as GC
function Fix-Pin
( 
        [String] $Pin
) 
{
    $pin = $pin.Replace("l", "L").Replace("o", "O")
    $pin = $pin.insert(5,'-').insert(11,'-')
    return $pin
}


# Mass generate keys and export to CSV
function Generate-Keys-To-File
( 
        [String]$inputfile,
        [String]$outputfile
) 
{
    $output =@()
    $input = Get-Content $inputfile
    ForEach ($email in $input) {
        Try {
            $process = Generate-Accesskey (Get-Userid $email)
            $process.pin= (Fix-Pin $process.pin)
        } Catch { 
            write-host $email "failed" 
            if ($process) { Clear-Variable process }
            }
        $output += $process
    }
    $output | select provId,pin | export-csv $outputfile 
}


# Get all App groups within GC
function Get-AppGroups {
    
    # Set Cap for CAP SOAP, not GC
    $cap = "true"
    # Get all GC App Groups
    $getGroupsEnvelope = (Build-Envelope "getGroups")
    $getGroupsRequest = (Execute-SOAPRequest $getGroupsEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$getGroupsRequest = $getGroupsRequest
    $getGroups = ($getGroupsRequest.Envelope.Body.getGroupsResponse.groups.group)
    return $getGroups
}

# Get group ID
function Get-AppGroupID 
(
    [string]$GroupName
)
{
    # Call get groups function
    $TempGroups = Get-AppGroups
    #Filter Result
    $GroupID = ($TempGroups | where {$_.group_name -EQ $GroupName}| select group_id).group_id
    return $GroupID
}

# Remove group ID from user ID
function Remove-UserID-From-GroupID
( 
        [String] $UserID,
        [String] $GroupID
) 
{
    # Set Cap for CAP SOAP, not GC
    $cap = "true"
    # Build envelope with ID's
    $removeGroupUserEnvelope = (Build-Envelope "removeGroupUser" "whodidthis" $WhoDidThis "group_id" $GroupID "user_id" $UserID)
    $removeGroupUserRequest = (Execute-SOAPRequest $removeGroupUserEnvelope $url)
    # No return codes from GC even if it goes wrong.
}

# Remove group name from user name
function Remove-User-From-Group
( 
        [String] $UserName,
        [String] $GroupName
) 
{
    $UserID = (Get-Userid $UserName)
    $GroupId = Get-AppGroupID $GroupName
    Remove-UserID-From-GroupID $UserID $GroupId 
}

# Add group ID from user ID
function Add-UserID-To-GroupID
( 
        [String] $UserID,
        [String] $GroupID
) 
{
    # Set Cap for CAP SOAP, not GC
    $cap = "true"
    # Build envelope with ID's
    $AddGroupUserEnvelope = (Build-Envelope "addGroupUser" "whodidthis" $WhoDidThis "group_id" $GroupID "user_id" $UserID)
    $AddGroupUserRequest = (Execute-SOAPRequest $AddGroupUserEnvelope $url)
    # No return codes from GC even if it goes wrong.
}

# Add group name from user name
function Add-User-To-Group
( 
        [String] $UserName,
        [String] $GroupName
) 
{
    $UserID = (Get-Userid $UserName)
    $GroupId = Get-AppGroupID $GroupName
    Add-UserID-To-GroupID $UserID $GroupId 
}

# Parse XML to text
Function ParseXML (
    $inputXML
)
{
    $xml = $inputXML
    $tmp = $xml.SelectNodes("//*")
    $cnt = $tmp.Count
    $output = for ($i = 0; $i -lt $tmp.Count; $i++) {
       $tmp.Item($i).InnerText
        } return $output
}

# Add AD user to GC
function Add-User
( 
        [String] $displayname,
        [String] $email
#        [String] $policysetid
) 
{
    # Add user to GC. 
    ### WIP ### Needs improvement
    if ($policysetid) {
        $AddUserEnvelope = (Build-Envelope "AddUserRequest" "displayName" $displayname "stringId" $email "policySetId" $polcysetid "domain" $env:userdnsdomain "securityRealm" "1" "deviceCount" "1") # Note that $env:userdnsdomain fetches the domain of the machine this script is executed. If the domain is different, change this to "mydomain.local".
    } else {
        $AddUserEnvelope = (Build-EnvelopeSingleSub "AddUserRequest" "user" "displayName" $displayname "stringId" $email "domain" $env:userdnsdomain "securityRealm" "1" "deviceCount" "1")
    }
    Try {
        $AddUserRequest = (Execute-SOAPRequest $AddUserEnvelope $url)
        }
    Catch 
        {
        write-host "$email failed. Either faulty unput, user doesn't exist in AD or user already exists. Otherwise SOAP problems with GC"
        #need better error handling
        }
}

# Add Remove User based on user ID
function Remove-UserID
( 
        [int] $UserID
) 
{
    # Build envelope with ID's
    $RemoveUserEnvelope = (Build-Envelope "RemoveUserRequest" "userId" $UserId)
    $RemoveUserRequest = (Execute-SOAPRequest $RemoveUserEnvelope $url)
    # No return codes from GC even if it goes wrong.
}

# Add Remove User based on user email
function Remove-User
( 
        [String] $UserName
) 
{
    # Translate email to userid
    $UserID = (Get-Userid $UserName)
    # Build envelope with ID's
    $RemoveUserEnvelope = (Build-Envelope "RemoveUserRequest" "userId" $UserId)
    $RemoveUserRequest = (Execute-SOAPRequest $RemoveUserEnvelope $url)
    # No return codes from GC even if it goes wrong.
}

function Add-ClientCertificate
( 
        [String] $CertFile,
        [Int] $UserID
) 
{
    $FileTemp = $CertFile.Split("\")
    $Filename = $FileTemp[-1]
    $Content = Get-Content -Path $CertFile -Encoding Byte
    $CertData = [System.Convert]::ToBase64String($Content)
    $AddClientCertificateEnvelope = (Build-Envelope "AddClientCertificateRequest" "certData" $CertData "fileName" $FileName "userId" $UserID)
    $AddClientCertificateRequest = (Execute-SOAPRequest $AddClientCertificateEnvelope $url)
}

# Get all users within GC
function Get-Users {
    
    $GetUsersEnvelope = (Build-Envelope "GetUsersRequest")
    $GetUsersRequest = (Execute-SOAPRequest $GetUsersEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetUsersRequest = $GetUsersRequest
    $GetUsers = ($GetUsersRequest.Envelope.Body.GetUsersResponse.users)
    return $GetUsers
}

# Get all administrators within GC
function Get-Administrators {
    
    $GetAdministratorsEnvelope = (Build-Envelope "GetAdministratorsRequest")
    $GetAdministratorsRequest = (Execute-SOAPRequest $GetAdministratorsEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetAdministratorsRequest = $GetAdministratorsRequest
    $GetAdministrators = ($GetAdministratorsRequest.Envelope.Body.GetAdministratorsResponse.adminlist)
    return $GetAdministrators
}

# Get all admin roles within GC
function List-Roles {
    
    $ListRolesEnvelope = (Build-Envelope "ListRolesRequest" "includeSelfService" "false")
    $ListRolesRequest = (Execute-SOAPRequest $ListRolesEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$ListRolesRequest = $ListRolesRequest
    $ListRoles = ($ListRolesRequest.Envelope.Body.ListRolesResponse.roleslist.roles)
    return $ListRoles
}

# Get Role ID from role name
function Get-RoleID 
( 
        [String] $RoleName
) 
{
    List-Roles | where {$_.rolename -eq $RoleName} | select roleid -ExpandProperty roleid
}

### Examples ###

# Getting the User ID from email address
#Get-Userid "user.name@email.domain"

# Generating Access key based on email address
#Generate-Accesskey (Get-Userid "user.name@email.domain")

# Display current keys for user based on email address. Output is xml
#$foo = Get-Accesskey (Get-Userid "user.name@email.domain")

# Display groups for user based on user id. Output is xml
#$foo = Get-GroupsForUser (Get-Userid "user.name@email.domain")

# Get all GC policies
#$foo = Get-AllPolicies

# Get policy details in XML format
#$foo = Get-PolicyDetail "1234"
# Export this xml to file
#$foo = Get-PolicyDetail "1234" | Export-Clixml "c:\policyexports\foo.xml"

# Get GC Properties
#$foo = Get-GCProperties

# Mass generate keys and export to CSV
#Generate-Keys-To-File "c:\inputusers.txt" "c:\outputfile.csv"

# Get all app groups
#$groups = Get-AppGroups

# Remove App Group from user
#Remove-UserID-From-GroupID (Get-Userid "user.name@email.domain") (Get-AppGroupID "Notate For Good Users")
#or
#Remove-User-From-Group "user.name@email.domain" "Notate For Good Users"

# Add App Group to user
#Add-UserID-To-GroupID (Get-Userid "user.name@email.domain") (Get-AppGroupID "Notate For Good Users")
#or
#Add-User-To-Group "user.name@email.domain" "Notate For Good Users"

# Add AD user to GC
#Add-User "lastname, firstname" "user.name@email.domain"

# Remove User
#Remove-User "user.name@email.domain"

# Remove UserID
#Remove-UserID "12345"

#remove-user "Chris.Johnson@gdbeslab.com"

# Upload certificate to user
#Add-ClientCertificate "C:\certificates\foo.p12" (Get-Userid "user.name@email.domain")

# Get all users from GC
#$foo = Get-Users

# Get all administrators from GC
#Get-Administrators

# List all admin roles in GC
#List-Roles

# Get Role ID of GC admin role
#Get-RoleID "Good Control Global Administrators"