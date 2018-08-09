###################################################
# GC Powershell to Soap Translator                #
# Created by Yoni Toorenspits                     #
# Inspiration and Soap code by Keith Schutte      #
# Special Thanks to Johan Eikelenboom for PS tips #
#                                                 #
# Version 1.6                                     #
# Released Jan 5th 2016                           #
# Revised July 28th 2016                          #
#                                                 #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2016 Yoni Toorenspits, Keith Schutte, Johan Eikelenboom and Vijayan Kumaran                                        #
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
        
        # Build headers and send Soap request
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
        $soapWebRequest.Headers.Add("SOAPAction",$urn+':gcServer:'+$SoapCommandFunction)
        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        # Initiating Send
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
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

# Same as above but no sub xml
function Build-EnvelopeStart
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
    $tempsoap += '<urn:'+$subname+'>'+$SoapInput1XML+$SoapInput2XML+$SoapInput3XML+$SoapInput4XML+$SoapInput5XML+$SoapInput6XML+'</urn:'+$subname+'>'
       
    return $tempsoap 
}

function Build-EnvelopeStartNoSub
( 
        [String] $SoapCommand,
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
    $tempsoap += $SoapInput1XML+$SoapInput2XML+$SoapInput3XML+$SoapInput4XML+$SoapInput5XML+$SoapInput6XML
       
    return $tempsoap 
}

# NEW envolope building. END function.
function Build-EnvelopeEnd 
( 
        [String] $SoapCommand
)
{
    # Close envelope
    $Soap ='</urn:'+$SoapCommand+'></soapenv:Body></soapenv:Envelope>'
    #Return value
    return $Soap
}

# NEW envolope building. Start function.
function Build-EnvelopeAdd
( 
        [String] $SoapCommand,
        [String] $SoapInput,
        [String] $SoapInputValue,
        [string] $SoapInput2,
        [string] $SoapInput2Value,
        [string] $SoapInput3,
        [string] $SoapInput3Value,
        [string] $SoapInput4,
        [string] $SoapInput4Value, 
        [string] $SoapInput5,
        [string] $SoapInput5Value,
        [string] $SoapInput6,
        [string] $SoapInput6Value,
        [string] $SoapInput7,
        [string] $SoapInput7Value    
) 
{ 
    # Build XML 
    

    # Build String input if exists
    if ($SoapInput) { $SoapInputXML =  "<urn:$SoapInput>$SoapInputValue</urn:$SoapInput>" }
    if ($SoapInput2) { $SoapInput2XML =  "<urn:$SoapInput2>$SoapInput2Value</urn:$SoapInput2>" }
    if ($SoapInput3) { $SoapInput3XML =  "<urn:$SoapInput3>$SoapInput3Value</urn:$SoapInput3>" }
    if ($SoapInput4) { $SoapInput4XML =  "<urn:$SoapInput4>$SoapInput4Value</urn:$SoapInput4>" }
    if ($SoapInput5) { $SoapInput5XML =  "<urn:$SoapInput5>$SoapInput5Value</urn:$SoapInput5>" }
    if ($SoapInput6) { $SoapInput6XML =  "<urn:$SoapInput6>$SoapInput6Value</urn:$SoapInput6>" }
    if ($SoapInput7) { $SoapInput7XML =  "<urn:$SoapInput7>$SoapInput7Value</urn:$SoapInput7>" }
            
    # Add to Envelope
    $tempsoap += '<urn:'+$SoapCommand+'>'+$SoapInputXML+$SoapInput2XML+$SoapInput3XML+$SoapInput4XML+$SoapInput5XML+$SoapInput6XML+$SoapInput7XML+'</urn:'+$SoapCommand+'>'
    

    return $tempsoap
}


# NEW envolope building. Start function.
function Build-EnvelopeAddSubStart
( 
        [String] $SubCommand

) 
{ 
           
    # Add to Envelope
    $tempsoap += '<urn:'+$SubCommand+'>'
    
    return $tempsoap
}

function Build-EnvelopeAddSubEnd
( 
        [String] $SubCommand

) 
{ 
           
    # Add to Envelope
    $tempsoap += '</urn:'+$SubCommand+'>'
    
    return $tempsoap
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

# Add AD Group to admin group GC (requires AD tools to be installed and AD permissions for account performing the script.
function Add-AdminFromADGroup
( 
        [String] $RoleName,
        [String] $ADGroup
) 
{
    # Get Role ID first
    [string]$RoleID = Get-RoleID $RoleName

    # Start the envelope
    $AddAdminFromADGroupEnvelope = (Build-EnvelopeStart "AddRoleMembersRequest" "role" "roleId" $RoleID "roleName" $RoleName)

    #AD part
    $Domain = Get-ADDomain | select forest -ExpandProperty forest
    $GroupUsers = get-adgroupmember $ADGroup -recursive | select sAMAccountName,Name 
    # Cycle through all members and add to envelope
    foreach ($RoleMember in $GroupUsers) {
        $sAMAccountname = $RoleMember.sAMAccountname
        $DisplayName = $RoleMember.Name
        $AddAdminFromADGroupEnvelope += (Build-EnvelopeAdd "members" "adminId" $sAMAccountname "displayName" $DisplayName "domain" $Domain)
    }

    # Now we close the envelope
    $AddAdminFromADGroupEnvelope += (Build-EnvelopeEnd "AddRoleMembersRequest")
    [xml]$AddAdminFromADGroupEnvelopeXML = $AddAdminFromADGroupEnvelope
    Execute-SOAPRequest $AddAdminFromADGroupEnvelopeXML $url | out-null

}

# Get all properties from the GC you query. For audit purposes.
function Get-AllConnectionProfiles {
    
    # Get all GC policies
    $GetAllConnectionProfileEnvelope = (Build-Envelope "GetAllConnectionProfileRequest")
    $GetAllConnectionProfileRequest = (Execute-SOAPRequest $GetAllConnectionProfileEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetAllConnectionProfileRequest = $GetAllConnectionProfileRequest
    $GetAllConnectionProfile = ($GetAllConnectionProfileRequest.Envelope.Body.GetAllConnectionProfileResponse.connectionProfileList | select profileId,name)
    return $GetAllConnectionProfile
}

# Add Profile Rule
function Add-ProfileRule
( 
        [string] $ConnectionProfile,
        [String] $Rule,
        [String] $FirstCluster,
        [String] $SecondCluster
) 
{
    # Get the connectionprofile ID
    $connectionProfileId = Get-AllConnectionProfiles | where {$_.name -eq $ConnectionProfile} | select profileid -ExpandProperty Profileid
    
    # Start the envelope
    $AddProfileRuleEnvelope = (Build-EnvelopeStartNoSub "UpdateConnectionProfileRulesRequest" "connectionProfileId" $connectionProfileId)

    # Fill the gaps
    $AddProfileRuleEnvelope +=("<urn:connectionProfileRules><urn:domainServers><urn:type>ADDITIONAL_SERVERS</urn:type><urn:domains><urn:id>0</urn:id><urn:domainName>$Rule</urn:domainName><urn:primaryRouteName>$FirstCluster</urn:primaryRouteName>")
    if ($SecondCluster) { $AddProfileRuleEnvelope+="<urn:secondaryRouteName>Second</urn:secondaryRouteName>"}
    $AddProfileRuleEnvelope+=("<urn:actionType>ADD</urn:actionType><urn:isDeleted>false</urn:isDeleted></urn:domains></urn:domainServers></urn:connectionProfileRules>")
    
    # Now we close the envelope
    $AddProfileRuleEnvelope += (Build-EnvelopeEnd "UpdateConnectionProfileRulesRequest")
    [xml]$AddProfileRuleEnvelopeXML = $AddProfileRuleEnvelope
    Execute-SOAPRequest $AddProfileRuleEnvelopeXML $url | out-null

}

# Add Allowed domain
function Add-AllowedDomain
( 
        [string] $ConnectionProfile,
        [String] $Rule,
        [String] $FirstCluster,
        [String] $SecondCluster
) 
{
    # Get the connectionprofile ID
    $connectionProfileId = (Get-AllConnectionProfiles | where {$_.name -eq $ConnectionProfile} | select profileid -ExpandProperty Profileid)
    
    # Start the envelope
    $AddProfileRuleEnvelope = (Build-EnvelopeStartNoSub "UpdateConnectionProfileRulesRequest" "connectionProfileId" $connectionProfileId)

    # Fill the gaps
    $AddProfileRuleEnvelope +=("<urn:connectionProfileRules><urn:domainServers><urn:type>ALLOWED_DOMAINS</urn:type><urn:domains><urn:id>0</urn:id><urn:domainName>$Rule</urn:domainName><urn:primaryRouteName>$FirstCluster</urn:primaryRouteName>")
    if ($SecondCluster) { $AddProfileRuleEnvelope+="<urn:secondaryRouteName>Second</urn:secondaryRouteName>"}
    $AddProfileRuleEnvelope+=("<urn:actionType>ADD</urn:actionType><urn:isDeleted>false</urn:isDeleted></urn:domains></urn:domainServers></urn:connectionProfileRules>")
    
    # Now we close the envelope
    $AddProfileRuleEnvelope += (Build-EnvelopeEnd "UpdateConnectionProfileRulesRequest")
    
    [xml]$AddProfileRuleEnvelopeXML = $AddProfileRuleEnvelope
    Execute-SOAPRequest $AddProfileRuleEnvelopeXML $url | out-null

}

function Get-ConnectionProfileAndRules
( 
        [string] $ConnectionProfile
) 
{
    # Get connectionprofile ID
    $connectionProfileId = (Get-AllConnectionProfiles | where {$_.name -eq $ConnectionProfile} | select profileid -ExpandProperty Profileid)


    $GetConnectionProfileAndRulesEnvelope = (Build-Envelope "GetConnectionProfileAndRulesRequest" "connectionProfileId" $connectionProfileId)
    $GetConnectionProfileAndRulesRequest = (Execute-SOAPRequest $GetConnectionProfileAndRulesEnvelope $url)
    $GetConnectionProfileAndRules = ($GetConnectionProfileAndRulesRequest.Envelope.Body.GetConnectionProfileAndRulesResponse.connectionProfileRules.domainServers.domains | select id,domainName)
    return $GetConnectionProfileAndRules
}

# Add Allowed domain
function Remove-AllowedDomain
( 
        [string] $ConnectionProfile,
        [String] $Rule
) 
{
    # Get the connectionprofile ID
    $connectionProfileId = (Get-AllConnectionProfiles | where {$_.name -eq $ConnectionProfile} | select profileid -ExpandProperty Profileid)
    
    # Get the rule ID
    $ruleId = (Get-ConnectionProfileAndRules "Master Connection Profile" | where {$_.domainName -eq $Rule} | select id -ExpandProperty id)


    # Start the envelope
    $AddProfileRuleEnvelope = (Build-EnvelopeStartNoSub "UpdateConnectionProfileRulesRequest" "connectionProfileId" $connectionProfileId)

    # Fill the gaps
    $AddProfileRuleEnvelope +=("<urn:connectionProfileRules><urn:domainServers><urn:type>ALLOWED_DOMAINS</urn:type><urn:domains><urn:id>0</urn:id>")
    $AddProfileRuleEnvelope+=("<urn:actionType>ADD</urn:actionType><urn:isDeleted>true</urn:isDeleted></urn:domains></urn:domainServers></urn:connectionProfileRules>")
    
    # Now we close the envelope
    $AddProfileRuleEnvelope += (Build-EnvelopeEnd "UpdateConnectionProfileRulesRequest")
    
    [xml]$AddProfileRuleEnvelopeXML = $AddProfileRuleEnvelope
    Execute-SOAPRequest $AddProfileRuleEnvelopeXML $url | out-null

}

# Add Application Connection Rule
function Add-AppRule
( 
        [String] $AppId,
        [String] $ServerHost,
        [String] $Port,
        [String] $PrimaryCluster,
        [String] $SecondaryCluster
) 
{

    # Start the envelope
    $AddOrUpdateApplicationServerEnvelope = (Build-EnvelopeStartNoSub "AddOrUpdateApplicationServerRequest" "appId" "$AppId")

    # Fill the gaps
    $AddOrUpdateApplicationServerEnvelope += ('<urn:applicationServers><urn:id>-1</urn:id><urn:server>'+$ServerHost+'</urn:server><urn:port>'+$Port+'</urn:port><urn:clusterType>PRIMARY</urn:clusterType><urn:primaryRouteName>'+$PrimaryCluster+'</urn:primaryRouteName>')
    if ($SecondaryCluster) { $AddProfileRuleEnvelope+= '<urn:secondaryRouteName>'+$SecondaryCluster+'</urn:secondaryRouteName>'}
    $AddOrUpdateApplicationServerEnvelope += ('<urn:actionType>ADD</urn:actionType></urn:applicationServers>')

    # Now we close the envelope
    $AddOrUpdateApplicationServerEnvelope += (Build-EnvelopeEnd "AddOrUpdateApplicationServerRequest")
    [xml]$AddOrUpdateApplicationServerEnvelopeXML = $AddOrUpdateApplicationServerEnvelope
    Execute-SOAPRequest $AddOrUpdateApplicationServerEnvelopeXML $url | out-null

}

# get devices from user based on user email
function Get-Devices
( 
        [String] $UserName
) 
{
    # Translate email to userid
    $UserID = (Get-Userid $UserName)
    # Build envelope with ID's
    $GetDevicesEnvelope = (Build-Envelope "GetDevicesRequest" "userId" $UserId)
    $GetDevicesRequest = (Execute-SOAPRequest $GetDevicesEnvelope $url)
    $GetDevices = ($GetDevicesRequest.Envelope.Body.GetDevicesResponse.deviceList)
    return $GetDevices   
} 

# get containers from user based on user email
function Get-ContainerList
( 
        [String] $UserName
) 
{
    # Translate email to userid
    $UserID = (Get-Userid $UserName)
    # Build envelope with ID's
    $GetDevicesEnvelope = (Build-Envelope "GetDevicesRequest" "userId" $UserId)
    $GetDevicesRequest = (Execute-SOAPRequest $GetDevicesEnvelope $url)
    $GetDevices = ($GetDevicesRequest.Envelope.Body.GetDevicesResponse.deviceList.containerList.containerList)
    return $GetDevices   
} 

# generate unlock for user based on user email and container ID (use Get-ContainerList)
function Generate-UnlockCode
( 
        [String] $UserName,
        [string] $ContainerId
) 
{
    # Translate email to userid
    $UserID = (Get-Userid $UserName)
    # Build envelope with ID's
    $GenerateUnlockCodeEnvelope = (Build-Envelope "GenerateUnlockAccessKeyRequest" "userId" $UserId "containerId" $ContainerId)
    $GenerateUnlockCodeRequest = (Execute-SOAPRequest $GenerateUnlockCodeEnvelope $url)
    $GenerateUnlockCode = ($GenerateUnlockCodeRequest.Envelope.Body.GenerateUnlockAccessKeyResponse.unlockAccessKey)
    return $GenerateUnlockCode  
} 

# Remove app based on container id
function Remove-App
( 
                [string] $ContainerId
) 
{
    # Translate email to userid
    $UserID = (Get-Userid $UserName)
    # Build envelope with ID's
    $RemoveAppEnvelope = (Build-Envelope "DeleteContainerRequest" "containerId" $ContainerId)
    $RemoveAppRequest = (Execute-SOAPRequest $RemoveAppEnvelope $url)
}

#Remove User based on sAMAcountname
function Remove-AdminFromAD
( 
        [String] $RoleName,
        [String] $member
        
) 
{
   # Get Role ID first
    [string]$RoleID = Get-RoleID $RoleName
 
    # Start the envelope
    $RemoveAdminFromADEnvelope = (Build-EnvelopeStartNoSub "RemoveRoleMemberRequest" "roleId" $RoleID)
 
    #AD part
    $Domain = Get-ADDomain | select forest -ExpandProperty forest
    $RemoveAdminFromADEnvelope += (Build-EnvelopeAdd "member" "adminId" $member “domain” $Domain)
 
    # Now we close the envelopes
    $RemoveAdminFromADEnvelope += (Build-EnvelopeEnd "RemoveRoleMemberRequest")
    [xml]$RemoveAdminFromADEnvelopeXML = $RemoveAdminFromADEnvelope
    Execute-SOAPRequest $RemoveAdminFromADEnvelopeXML $url | out-null
 
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

# Upload certificate to user
#Add-ClientCertificate "C:\Users\adm-ytoorens\Desktop\test.com.p12" (Get-Userid "user.name@email.domain")

# Get all users from GC
#$foo = Get-Users

# Get all administrators from GC
#Get-Administrators

# List all admin roles in GC
#List-Roles

# Get Role ID of GC admin role
#Get-RoleID "Good Control Global Administrators"

# Add Admins to GC from AD group. First entry is GC group, second AD Group. Requires AD powershell to be installed. Works recursive and only on local domain (not multi domain)
#Add-AdminFromADGroup "Good Control Global Administrators" "Mobility Administration"

# Add connections to the master connection profile. Second cluster is optional
#Add-ProfileRule "Master Connection Profile" "blabla.com:443" "First" "Second"

# Add connections to an app. Secon cluster is optional
#Add-AppRule "com.good.gcs.g3" "test.com" "443" "First" "Second"

# Get Devices listed for a specific user
#Get-Devices "user.name@email.domain"

# Get container list for user. Use this to filter the container you want to create an unlock code for.
#Get-ContainerList "user.name@email.domain"

# Generate Unlock Code
#Generate-UnlockCode "user.name@email.domain" "9C9A7EAF-6285-476B-A21F-0E284D97BF2E"

# Remove App from Device list
#Remove-App "9C9A7EAF-6285-476B-A21F-0E284D97BF2E"

# Add allowed domain
#Add-AllowedDomain "Master Connection Profile" "*.contoso.com" "First"

# Get list of connection profiles
#Get-AllConnectionProfiles

# List all rules (domain and additional servers) on a connectivity profile
#Get-ConnectionProfileAndRules "Master Connection Profile"