################################################################
# BlackBerry BES/UEM Webservices Powershell to Soap Translator #
# Created by Yoni Toorenspits                                  #
#                                                              #
# Version 0.3                                                  #
# Released Feb 10th 2017                                       #
# Revised September 20th 2018                                  #
#                                                              #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2017 Yoni Toorenspits. SOAP auth code by Srinivasa Tumarada                                                        #
####################################################################################################################### 

#### NOTES #####
# THIS SCRIPT HAS ONLY BEEN TESTED USING THE BUILT IN LOCAL ADMIN ACCOUNT


# Variables. Edit accordingly
$UEMHost = "uemga01.gdbeslab.com" #FQDN of your UEM server
$UEMPort = "18084" #BWS port number, default is 18084
$UEMUser = "admin"
$UEMPassword = "YeahRightHAHAHA"

# Disable SSL verification ($true = disabled, $false = enabled) Only disable for testing purposes! Install a trusted certificate for BWS in UEM and ensure SSL verification is done properly!
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Construct SOAP Urls
$BWSUrl = "https://"+$UEMHost+":"+$UEMPort+"/enterprise/admin/ws"
$BWSUtilUrl = "https://"+$UEMHost+":"+$UEMPort+"/enterprise/admin/util/ws"

# Execute soap with auth
Function Soap_Request_Basicauth() 
{ 
Param ( 
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)] 
            [xml]$SOAP_Request, 
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)] 
            [String]$URL, 
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)] 
            [string]$Uname, 
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)] 
            [string]$Password 
        
    ) 
 
    Begin {  } 
 
    Process { 
     
    $SOAPRequest = $SOAP_Request 
     
     
    $Soap_WebRequest = [System.Net.WebRequest]::Create($URL) 
     
    [string]$authInfo = $uname + ":" + $Password 
    [string]$authInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($uname + ':' + $password)) 
    $Soap_webRequest.Headers.Add("AUTHORIZATION","Basic $authinfo") 
    $Soap_WebRequest.Headers.Add("SOAPAction","`"`"") 
    $Soap_WebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
    $Soap_WebRequest.Accept      = "text/xml" 
    $Soap_WebRequest.Method      = "POST" 
 

     
    $RequestStream = $soap_WebRequest.GetRequestStream() 
    $SOAPRequest.Save($requestStream) 
    $requestStream.Close() 
 
         
     $resp = $soap_WebRequest.GetResponse() 
     $responseStream = $resp.GetResponseStream() 
     $soapReader = [System.IO.StreamReader]($responseStream) 
     $ReturnXml = [Xml] $soapReader.ReadToEnd() 
     $responseStream.Close() 
 
      
     } 
 
     End {  write-output $Returnxml } 
 
}

# Execute SOAP without auth
Function Soap_Request_NoAuth() 
{ 
Param ( 
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)] 
            [xml]$SOAP_Request, 
            [Parameter(Mandatory=$True,ValueFromPipeline=$False,ValueFromPipelinebyPropertyName=$False)] 
            [String]$URL
       
    ) 
 
    Begin {  } 
 
    Process { 
     
    $SOAPRequest = $SOAP_Request 
     
  
    $Soap_WebRequest = [System.Net.WebRequest]::Create($URL) 
     
    $Soap_WebRequest.Headers.Add("SOAPAction","`"`"") 
    $Soap_WebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
    $Soap_WebRequest.Accept      = "text/xml" 
    $Soap_WebRequest.Method      = "POST" 
 
    
    $RequestStream = $soap_WebRequest.GetRequestStream() 
    $SOAPRequest.Save($requestStream) 
    $requestStream.Close() 
 
        
     $resp = $soap_WebRequest.GetResponse() 
     $responseStream = $resp.GetResponseStream() 
     $soapReader = [System.IO.StreamReader]($responseStream) 
     $ReturnXml = [Xml] $soapReader.ReadToEnd() 
     $responseStream.Close() 
 
      

     } 
 
     End {  write-output $Returnxml } 
 
}


# Function required for encoding the username
Function GetEncodedUserName
(
    [String] $AdminUser = "admin"
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
       <soapenv:Header/>
       <soapenv:Body>
          <adm:GetEncodedUsernameRequest>
             <adm:metadata>
                <adm:locale>en_US</adm:locale>
                <adm:clientVersion>12</adm:clientVersion>
                <adm:organizationUid>0</adm:organizationUid>
             </adm:metadata>
             <adm:username>'+$AdminUser+'</adm:username>
             <adm:authenticator>
                <adm:uid>BlackBerry Administration Service</adm:uid>
                <adm:authenticatorType>
                   <adm:INTERNAL>true</adm:INTERNAL>
                   <adm:PLUGIN>false</adm:PLUGIN>
                   <adm:UNSUPPORTED_VALUE>false</adm:UNSUPPORTED_VALUE>
                   <adm:value>INTERNAL</adm:value>
                </adm:authenticatorType>
                <adm:name>BlackBerry Administration Service</adm:name>
                <adm:externalUid></adm:externalUid>
             </adm:authenticator>
             <adm:credentialType>
                <adm:PASSWORD>true</adm:PASSWORD>
                <adm:SSO>false</adm:SSO>
                <adm:UNSUPPORTED_VALUE>false</adm:UNSUPPORTED_VALUE>
                <adm:value></adm:value>
             </adm:credentialType>
          </adm:GetEncodedUsernameRequest>
       </soapenv:Body>
    </soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_NoAuth -Soap_Request ($soap_object.Innerxml) -URL $BWSUtilUrl) 
    $Status=($response.Envelope.Body.GetEncodedUsernameResponse.encodedUsername) 
    return $Status
}

# Function for getting user GUID. Input is user login name. When it concerns AD users, samaccountname attribute is used.
Function GetUserGuid
(
    [String] $UserName
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
   <soapenv:Header/>
   <soapenv:Body>
      <adm:GetUsersRequest>
         <adm:metadata>
            <adm:locale>en_US</adm:locale>
            <adm:clientVersion>12</adm:clientVersion>
            <adm:organizationUid>0</adm:organizationUid>
         </adm:metadata>
         <adm:searchCriteria>
            <adm:loginName>'+$UserName+'</adm:loginName>
         </adm:searchCriteria>
         <adm:sortBy>
            <adm:DISPLAY_NAME>true</adm:DISPLAY_NAME>
            <adm:USER_UID>false</adm:USER_UID>
            <adm:USER_NAME>false</adm:USER_NAME>
            <adm:DEVICE_PIN>false</adm:DEVICE_PIN>
            <adm:DEVICE_MODEL>false</adm:DEVICE_MODEL>
            <adm:DEVICE_CARRIER>false</adm:DEVICE_CARRIER>
            <adm:DEVICE_PHONE_NUMBER>false</adm:DEVICE_PHONE_NUMBER>
            <adm:IT_POLICY>false</adm:IT_POLICY>
            <adm:BES>false</adm:BES>
            <adm:EMAIL_ADDRESS>false</adm:EMAIL_ADDRESS>
            <adm:MAIL_SERVER_NAME>false</adm:MAIL_SERVER_NAME>
            <adm:USER_STATE>false</adm:USER_STATE>
            <adm:LAST_CONTACT_DATE>false</adm:LAST_CONTACT_DATE>
            <adm:UNSUPPORTED_VALUE>false</adm:UNSUPPORTED_VALUE>
            <adm:DEVICE_ACTIVE_CARRIER>false</adm:DEVICE_ACTIVE_CARRIER>
         </adm:sortBy>
         <adm:sortAscending>true</adm:sortAscending>
         <adm:pageSize>1</adm:pageSize>
      </adm:GetUsersRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    $Status=($response.Envelope.Body.GetUsersResponse.users.uid) 
    return $Status
}

# Function for setting specific activation password for a user. Use "GetUserGuid" for user GUID input. Optionally the expiry can be set, default is 48 hours. There will be NO EMAIL sent to the user!
Function SetUsersActivationPassword
(
    [String] $UserGuid,
    [String] $ActivationPassword,
    [int] $ExpiryHours = "48"
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
   <soapenv:Header/>
   <soapenv:Body>
      <adm:SetUsersActivationPasswordRequest>
         <adm:metadata>
            <adm:locale>en_US</adm:locale>
            <adm:clientVersion>12</adm:clientVersion>
            <adm:organizationUid>0</adm:organizationUid>
         </adm:metadata>
         <adm:users>
            <adm:uid>'+$UserGuid+'</adm:uid>
         </adm:users>
         <adm:activationPassword>'+$ActivationPassword+'</adm:activationPassword>
         <adm:expiryHours>'+$ExpiryHours+'</adm:expiryHours>
         <adm:generateAndEmailRandomPassword>false</adm:generateAndEmailRandomPassword>
         <adm:clearUsersActivationPassword>false</adm:clearUsersActivationPassword>
         <adm:useExternalDirectoryAuthentication>false</adm:useExternalDirectoryAuthentication>
      </adm:SetUsersActivationPasswordRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    #$Status=($response.Envelope.Body.SetUsersActivationPasswordResponse.returnStatus.code) 
    $Status=($response.Envelope.Body.SetUsersActivationPasswordResponse.individualResponses.returnStatus.code) 
    return $Status
}

# Function for auto generating activation password for a user. Use "GetUserGuid" for user GUID input. Optionally the expiry can be set, default is 48 hours. There WILL be an email sent to the user using de default template.
Function SetUsersActivationPasswordAutoGenerate
(
    [String] $UserGuid,
    [int] $ExpiryHours = "48"
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
   <soapenv:Header/>
   <soapenv:Body>
      <adm:SetUsersActivationPasswordRequest>
         <adm:metadata>
            <adm:locale>en_US</adm:locale>
            <adm:clientVersion>12</adm:clientVersion>
            <adm:organizationUid>0</adm:organizationUid>
         </adm:metadata>
         <adm:users>
            <adm:uid>'+$UserGuid+'</adm:uid>
         </adm:users>
         <adm:expiryHours>'+$ExpiryHours+'</adm:expiryHours>
         <adm:generateAndEmailRandomPassword>true</adm:generateAndEmailRandomPassword>
         <adm:clearUsersActivationPassword>false</adm:clearUsersActivationPassword>
         <adm:useExternalDirectoryAuthentication>false</adm:useExternalDirectoryAuthentication>
      </adm:SetUsersActivationPasswordRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    #$Status=($response.Envelope.Body.SetUsersActivationPasswordResponse.returnStatus.code) 
    $Status=($response.Envelope.Body.SetUsersActivationPasswordResponse.individualResponses.returnStatus.code) 
    return $Status
}

# Function for getting group GUID. Input is group name.
Function GetGroupGuid
(
    [String] $GroupName
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
   <soapenv:Header/>
   <soapenv:Body>
       <adm:GetGroupsRequest>
         <adm:metadata>
            <adm:locale>en_US</adm:locale>
            <adm:clientVersion>12</adm:clientVersion>
            <adm:organizationUid>0</adm:organizationUid>
         </adm:metadata>
         <adm:name>'+$GroupName+'</adm:name>
      </adm:GetGroupsRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    $Status=($response.Envelope.Body.GetGroupsResponse.groups.uid) 
    return $Status
}

# Function for adding users to groups. Input is group GUID name and user GUID.
Function assignUsersToGroup
(
    [String] $UserGuid,
    [string] $GroupGuid
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
   <soapenv:Header/>
   <soapenv:Body>
      <adm:AssignUsersToGroupRequest>
         <adm:metadata>
            <adm:locale>en_US</adm:locale>
            <adm:clientVersion>12</adm:clientVersion>
            <adm:organizationUid>0</adm:organizationUid>
         </adm:metadata>
         <adm:users>
            <adm:uid>'+$UserGuid+'</adm:uid>
         </adm:users>
         <adm:group>
            <adm:uid>'+$GroupGuid+'</adm:uid>
         </adm:group>
      </adm:AssignUsersToGroupRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    $Status=($response.Envelope.Body.assignUsersToGroup) 
    return $Status
}


# Function for removing users from groups. Input is group GUID name and user GUID.
Function unassignUsersFromGroup
(
    [String] $UserGuid,
    [string] $GroupGuid
)
{
    $soapvar='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:adm="http://ws.rim.com/enterprise/admin">
   <soapenv:Header/>
   <soapenv:Body>
      <adm:UnassignUsersFromGroupRequest>
         <adm:metadata>
            <adm:locale>en_US</adm:locale>
            <adm:clientVersion>12</adm:clientVersion>
            <adm:organizationUid>0</adm:organizationUid>
         </adm:metadata>
         <adm:users>
            <adm:uid>'+$UserGuid+'</adm:uid>
         </adm:users>
         <adm:group>
            <adm:uid>'+$GroupGuid+'</adm:uid>
            <adm:groupType>
               <adm:NATIVE>false</adm:NATIVE>
               <adm:EXTERNAL>false</adm:EXTERNAL>
               <adm:DYNAMIC>false</adm:DYNAMIC>
               <adm:UNSUPPORTED_VALUE>false</adm:UNSUPPORTED_VALUE>
            </adm:groupType>
         </adm:group>
      </adm:UnassignUsersFromGroupRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    $Status=($response.Envelope.Body.unassignUsersFromGroup) 
    return $Status
}

## BWS Util Service functions examples
#
# Decoding a username
#GetEncodedUserName "admin"


## BWS Service functions example
#
# Function to get user GUID based on username
#GetUserGuid "adm-ytoorens"

# Function to set activation password based on user guid. First parameter is user guid, second parameter is the activation password, third is optional for the expiration time in hours.    
#SetUsersActivationPassword (GetUserGuid "adm-ytoorens") "12345" "72"

# Function to auto generate password based on user guid. First parameter is user guid, second parameter is optional for the expiration time in hours
#SetUsersActivationPasswordAutoGenerate (GetUserGuid "adm-ytoorens") "72"

# Function for getting group GUID. Input is group name.
#GetGroupGuid "foo"

# Function for adding users to groups. Input is group GUID name and user GUID.
#assignUsersToGroup (GetUserGuid "adm-ytoorens") (GetGroupGuid "foo") 

# Function for removing users from groups. Input is group GUID name and user GUID.
#unassignUsersFromGroup (GetUserGuid "adm-ytoorens") (GetGroupGuid "foo") 