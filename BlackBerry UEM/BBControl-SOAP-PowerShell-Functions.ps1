###################################################
# GC Powershell to Soap Translator                #
# Created by Yoni Toorenspits                     #
# Inspiration and Soap code by Keith Schutte      #
# Special Thanks to Johan Eikelenboom for PS tips #
#                                                 #
# Version 1.0                                     #
# Released Jan 5th 2016                           #
# Revised May 23rd 2018                           #
#                                                 #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2016 Yoni Toorenspits, Keith Schutte, Johan Eikelenboom and Vijayan Kumaran                                        #
#######################################################################################################################


# Set vars
$GCHost = "uemga01.gdbeslab.com:18084" # The GC host to target for SOAP calls
$GoodServiceAcct = "gdbeslab\myAdminUser" # Username for GC
$GoodServiceAcctPW = "Changeme01"# Password for GC user

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


# Fetch user id function. Input must be matching email address.
function Get-Userid
( 
        [String] $EmailInput
) 
{
    $GetUserEnvelope = (Build-Envelope "GetUserRequest" "stringId" $emailInput)
    [xml]$GetUserIdRequest = (Execute-SOAPRequest $GetUserEnvelope $url)
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
    [xml]$GetAccesskeyRequest = (Execute-SOAPRequest $GetAccesskeyEnvelope $url)
    # Convert var to XML for proper output.
    [xml]$GetAccesskeyRequest = $GetAccesskeyRequest
    $GetAccesskey = $GetAccesskeyRequest.Envelope.Body.GetAccessKeysResponse.containerList.pin.'#text'
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
            [xml]$GenerateAccesskeyRequest = (Execute-SOAPRequest $GenerateAccesskeyEnvelope $url)
            [xml]$GenerateAccesskeyRequest = $GenerateAccesskeyRequest
            $GenerateAccesskey = $GenerateAccesskeyRequest.Envelope.Body.GenerateAccessKeysResponse.containerList.pin
            return $GenerateAccesskey
            #write-host $GenerateAccesskey
            }
        }
    END {}
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
    [xml]$GetDevicesRequest = (Execute-SOAPRequest $GetDevicesEnvelope $url)
    $GetDevices = ($GetDevicesRequest.Envelope.Body.GetDevicesResponse.deviceList.containerList.containerList)
    return $GetDevices   
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
    [xml]$AddClientCertificateRequest = (Execute-SOAPRequest $AddClientCertificateEnvelope $url)
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
    [xml]$GenerateUnlockCodeRequest = (Execute-SOAPRequest $GenerateUnlockCodeEnvelope $url)
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
    [xml]$RemoveAppRequest = (Execute-SOAPRequest $RemoveAppEnvelope $url)
}



### Examples ###

# Getting the User ID from email address
#Get-Userid "user.name@email.domain"

# Generating Access key based on email address
#Generate-Accesskey (Get-Userid "user.name@email.domain")

# Display current keys for user based on email address. Output is xml
#$foo = Get-Accesskey (Get-Userid "user.name@email.domain")

# Upload certificate to user
#Add-ClientCertificate "C:\Users\adm-ytoorens\Desktop\test.com.p12" (Get-Userid "user.name@email.domain")

# Get container list for user. Use this to filter the container you want to create an unlock code for.
#Get-ContainerList "user.name@email.domain"

# Generate Unlock Code
#Generate-UnlockCode "user.name@email.domain" "9C9A7EAF-6285-476B-A21F-0E284D97BF2E"

# Remove App from Device list
#Remove-App "9C9A7EAF-6285-476B-A21F-0E284D97BF2E"