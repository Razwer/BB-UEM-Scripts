################################################################
# BlackBerry BES/UEM Webservices local group management GUI    #
# Created by Yoni Toorenspits                                  #
#                                                              #
# Version 0.1                                                  #
# Created Nov 9th 2018                                         #
#                                                              #
#                                                              #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2018 Yoni Toorenspits. SOAP auth code by Srinivasa Tumarada                                                        #
####################################################################################################################### 

# Disable SSL verification ($true = disabled, $false = enabled) Only disable for testing purposes! Install a trusted certificate for BWS in UEM and ensure SSL verification is done properly!
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{ 

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '720,450'
$Form.text                       = "Remove or Add Users From/To UEM Group"
$Form.TopMost                    = $false

$UEMServerLabel                  = New-Object system.Windows.Forms.Label
$UEMServerLabel.text             = "UEM Server FQDN"
$UEMServerLabel.AutoSize         = $true
$UEMServerLabel.width            = 25
$UEMServerLabel.height           = 10
$UEMServerLabel.location         = New-Object System.Drawing.Point(18,300)
$UEMServerLabel.Font             = 'Microsoft Sans Serif,10'

$UEMPortLabel                    = New-Object system.Windows.Forms.Label
$UEMPortLabel.text               = "Webservices Port"
$UEMPortLabel.AutoSize           = $true
$UEMPortLabel.width              = 25
$UEMPortLabel.height             = 10
$UEMPortLabel.location           = New-Object System.Drawing.Point(190,300)
$UEMPortLabel.Font               = 'Microsoft Sans Serif,10'

$GroupsList                      = New-Object system.Windows.Forms.ListBox
$GroupsList.text                 = "Groups List"
$GroupsList.width                = 215
$GroupsList.height               = 275
$GroupsList.location             = New-Object System.Drawing.Point(18,35)

$GetGroups                       = New-Object system.Windows.Forms.Button
$GetGroups.text                  = "Get Groups"
$GetGroups.width                 = 100
$GetGroups.height                = 30
$GetGroups.location              = New-Object System.Drawing.Point(18,400)
$GetGroups.Font                  = 'Microsoft Sans Serif,10'

$OpenUsersFile                   = New-Object system.Windows.Forms.Button
$OpenUsersFile.text              = "Browse Users Input File"
$OpenUsersFile.width             = 100
$OpenUsersFile.height            = 50
$OpenUsersFile.location          = New-Object System.Drawing.Point(320,300)
$OpenUsersFile.Font              = 'Microsoft Sans Serif,10'

$Execute                         = New-Object system.Windows.Forms.Button
$Execute.text                    = "Remove Users From Group"
$Execute.width                   = 160
$Execute.height                  = 50
$Execute.location                = New-Object System.Drawing.Point(230,390)
$Execute.Font                    = 'Microsoft Sans Serif,10'

$Execute2                         = New-Object system.Windows.Forms.Button
$Execute2.text                    = "Add Users To Group"
$Execute2.width                   = 160
$Execute2.height                  = 50
$Execute2.location                = New-Object System.Drawing.Point(400,390)
$Execute2.Font                    = 'Microsoft Sans Serif,10'

$Close                           = New-Object system.Windows.Forms.Button
$Close.text                      = "Close Application"
$Close.width                     = 100
$Close.height                    = 50
$Close.location                  = New-Object System.Drawing.Point(610,390)
$Close.Font                      = 'Microsoft Sans Serif,10'

$ClearWorkLog                    = New-Object system.Windows.Forms.Button
$ClearWorkLog.text               = "Clear Worklog"
$ClearWorkLog.width              = 100
$ClearWorkLog.height             = 50
$ClearWorkLog.location           = New-Object System.Drawing.Point(610,305)
$ClearWorkLog.Font               = 'Microsoft Sans Serif,10'


$UsersList                       = New-Object system.Windows.Forms.ListBox
$UsersList.width                 = 160
$UsersList.height                = 275
$UsersList.location              = New-Object System.Drawing.Point(260,35)
$UsersList.Font                  = 'Microsoft Sans Serif,10'

$WorkLog                         = New-Object system.Windows.Forms.RichTextBox
$WorkLog.multiline               = $True
$WorkLog.width                   = 250
$WorkLog.height                  = 250
$WorkLog.location                = New-Object System.Drawing.Point(450,35)
$WorkLog.Font                    = 'Microsoft Sans Serif,10'
$WorkLog.Scrollbars              = "Vertical" 
$WorkLog.SelectionStart          = $WorkLog.Text.Length

$GetCredentials                  = New-Object system.Windows.Forms.Button
$GetCredentials.text             = "Enter UEM Credentials"
$GetCredentials.width            = 180
$GetCredentials.height           = 30
$GetCredentials.location         = New-Object System.Drawing.Point(18,360)
$GetCredentials.Font             = 'Microsoft Sans Serif,10'

$UEMServer                       = New-Object system.Windows.Forms.TextBox
$UEMServer.multiline             = $false
$UEMServer.width                 = 186
$UEMServer.height                = 20
$UEMServer.location              = New-Object System.Drawing.Point(18,320)
$UEMServer.Font                  = 'Microsoft Sans Serif,10'
$UEMServer.Text                  = "my.uem.server.fqdn"


$UEMPort                         = New-Object system.Windows.Forms.TextBox
$UEMPort.multiline               = $false
$UEMPort.width                   = 53
$UEMPort.height                  = 20
$UEMPort.location                = New-Object System.Drawing.Point(215,320)
$UEMPort.Font                    = 'Microsoft Sans Serif,10'
$UEMPort.Text                    = "18084"

$SSLEnabledBox                   = New-Object system.Windows.Forms.CheckBox
$SSLEnabledBox.text              = "SSL Check"
$SSLEnabledBox.AutoSize          = $false
$SSLEnabledBox.width             = 95
$SSLEnabledBox.height            = 20
$SSLEnabledBox.location          = New-Object System.Drawing.Point(224,356)
$SSLEnabledBox.Font              = 'Microsoft Sans Serif,10'
$SSLEnabledBox.Checked           = $true

#$Form.controls.AddRange(@($GroupsList,$GetGroups,$OpenUsersFile,$Execute,$Close,$UsersList,$WorkLog,$ClearWorkLog,$GetCredentials,$UEMServer,$UEMPort,$Execute2,$UEMServerLabel,$UEMPortLabel,$SSLEnabledBox))
$Form.controls.AddRange(@($GroupsList,$GetGroups,$OpenUsersFile,$Execute,$Close,$UsersList,$WorkLog,$ClearWorkLog,$GetCredentials,$UEMServer,$UEMPort,$Execute2,$UEMServerLabel,$UEMPortLabel))

#region gui events {
$GetGroups.Add_Click({ FetchGroups })
$OpenUsersFile.Add_Click({ FetchUsers })
$Execute.Add_Click({ RemoveUsers })
$Execute2.Add_Click({ AddUsers })
$close.Add_Click({ closeForm })
$ClearWorkLog.Add_Click({ ClearWorkLog })
$GetCredentials.Add_Click({ SetUEMCreds })
#endregion events }

#endregion GUI }


#Write your logic code here

function closeForm(){$Form.close()}

function ClearWorkLog(){$WorkLog.text = ''}

function SetUEMCreds(){
    ($Creds = Get-Credential) 
    $Global:UEMUser = ($Creds.UserName)  
    $Global:UEMPassword = ($Creds.GetNetworkCredential().password)
}

function UEMVerification() {
    if (!$Global:UEMUser) {
        [System.Windows.MessageBox]::Show('No credentials entered!')
        $WorkLog.text += "`r`nNo Credentials!"
        $WorkLog.ScrollToCaret()
        return "no creds" 
        } elseif ($UEMServer.Text -eq "my.uem.server.fqdn") {
        $WorkLog.text += "`r`nNo Server entered!"
        $WorkLog.ScrollToCaret()
        return "no server" 
        } 

    
}

function FetchGroups(){ 
#Clean up list
$GroupsList.Items.Clear()

#Fetch groups and list in listbox    
    $WorkLog.text += "`r`nFetching Groups"
    $WorkLog.ScrollToCaret()
   
    $UEMHost = ($UEMServer.Text)      
    $UEMPort = ($UEMPort.Text);   
    #Reconstruct SOAP Urls as global
    $Global:BWSUrl = "https://"+$UEMHost+":"+$UEMPort+"/enterprise/admin/ws"
    $Global:BWSUtilUrl = "https://"+$UEMHost+":"+$UEMPort+"/enterprise/admin/util/ws"

    
    #check for UEM creds and settings
    $UEMVerification = UEMVerification
    If (!$UEMVerification) {
        $GroupsFetch = GetGroups
        foreach ($Group in $GroupsFetch) { 
            $GroupNameShow = ($group.Name)
            [void] $GroupsList.Items.Add("$GroupNameShow")
        }
    }
}


Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "TXT (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}


function FetchUsers(){ 
    #Clean up list
    $UsersList.Items.Clear()

    #Worklog Entry
    $WorkLog.text += "`r`nFetching Users"

    #Prompt for open file dialog
    $InputFileName = Get-FileName 

    #Spit out user list
    $UserNameShow = (Get-Content $InputFileName)
        foreach ($UserName in $UserNameShow) { 
            [void] $UsersList.Items.Add("$UserName")
        }
}

function RemoveUsers(){ 
    # Catch error if no groups are selected
    if (!$GroupsList.SelectedItem) { [System.Windows.MessageBox]::Show('No groups selected!') }
    Elseif 
        (!$UsersList.Items) { [System.Windows.MessageBox]::Show('No Users loaded!') }
    Else        
        {

        #Verify if SSL checking should be enabled
        if($SSLEnabledBox.Checked  -eq $true) {
            $Global:SSLEnabled = 'true'
        } else {
            $Global:SSLEnabled = 'false'
        }

        #Worklog entry
        $WorkLog.text += "`r`nStarting Removal of Users from group"
        $WorkLog.ScrollToCaret()

        $SelectedGroupName = $GroupsList.SelectedItem
        $SelectedGroupGuid = (GetGroupGuid $SelectedGroupName)
        Foreach ($UserEntry in $UsersList.Items) {
            #worklog entry
            $WorkLog.text += "`r`nprocessing user $userentry"
            $WorkLog.ScrollToCaret()

            unassignUsersFromGroup (GetUserGuid $UserEntry) $SelectedGroupGuid
        }
    }
}

function AddUsers(){ 
    # Catch error if no groups are selected
    if (!$GroupsList.SelectedItem) { [System.Windows.MessageBox]::Show('No groups selected!') }
    Elseif 
        (!$UsersList.Items) { [System.Windows.MessageBox]::Show('No Users loaded!') }
    Else        
        {
        
        #Verify if SSL checking should be enabled
        if($SSLEnabledBox.Checked  -eq $true) {
            $Global:SSLEnabled = 'true'
        } else {
            $Global:SSLEnabled = 'false'
        }

        #Worklog entry
        $WorkLog.text += "`r`nStarting Adding of Users to group"
        $WorkLog.ScrollToCaret()

        $SelectedGroupName = $GroupsList.SelectedItem
        $SelectedGroupGuid = (GetGroupGuid $SelectedGroupName)
        Foreach ($UserEntry in $UsersList.Items) {
            #worklog entry
            $WorkLog.text += "`r`nprocessing user $userentry"
            $WorkLog.ScrollToCaret()

            assignUsersToGroup (GetUserGuid $UserEntry) $SelectedGroupGuid
        }
    }
}



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

# Function to transpose data from XML to powershell table. Source: https://stackoverflow.com/questions/33649558/change-the-script-to-export-groups-and-nested-objects-differently/33650945#33650945
function Transpose-Data{
    param(
        [String[]]$Names,
        [Object[][]]$Data
    )
    for($i = 0;; ++$i){
        $Props = [ordered]@{}
        for($j = 0; $j -lt $Data.Length; ++$j){
            if($i -lt $Data[$j].Length){
                $Props.Add($Names[$j], $Data[$j][$i])
            }
        }
        if(!$Props.get_Count()){
            break
        }
        [PSCustomObject]$Props
    }
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

# Function to fetch all groups by name from UEM
Function GetGroups
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
         <adm:name></adm:name>
      </adm:GetGroupsRequest>
   </soapenv:Body>
</soapenv:Envelope>'
    $soap_object = [xml]$soapvar
    $Response=(Soap_Request_Basicauth -uname (GetEncodedUserName($UEMUser)) -password $UEMPassword -Soap_Request ($soap_object.Innerxml) -URL $BWSUrl) 
    $Guid = ($response.Envelope.Body.GetGroupsResponse.groups.uid) 
    $Name = ($response.Envelope.Body.GetGroupsResponse.groups.localeNameAndDescription.name) 
    $Status = (Transpose-Data Name, Guid $Name, $Guid)
    return $Status
}

#Show the form
[void]$Form.ShowDialog()