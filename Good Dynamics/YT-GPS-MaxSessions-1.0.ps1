###################################################
# GP Max Sessions changer for whole farm          #
# Created by Yoni Toorenspits                     #
#                                                 #
# Version 1.0                                     #
# Released Jan 13th 2016                          #
#                                                 #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2016 Yoni Toorenspits                                                                                              #
#######################################################################################################################

###########################
# Edit the settings Below #
###########################

$DesiredValue = "60000" # Set amount of sessions
$Farm = ("rws-ipvw-gpr005.ad.rws.nl","rws-ipvw-gpr006.ad.rws.nl","rws-ipvw-gpr007.ad.rws.nl","rws-ipvw-gpr008.ad.rws.nl","rws-ipvw-gpr009.ad.rws.nl","rws-ipvw-gpr010.ad.rws.nl") # List all GP servers you want to target
$OtherUser = $true # Set to $true for credentials to pop up.
$Path = "c:\Good\gps.properties"

# Don't edit this
$ServiceName = "GPS"


$ScriptBlock = {
 # Fetch input params
 Param
      (
        [String]$DesiredValue,
        [String]$Path,
        [String]$Computer,
        [String]$ServiceName
      )
    #debug
    write-host "Currently targetting $Computer" -ForegroundColor Green

    # Check if the path exists
    if (test-path -Path $Path) {
        $GPSProperties = (Get-Content $Path)
    }
    $MaxSessions = $GPSProperties | Select-String "gps.max.sessions"
    $MaxSessionsCurrentValue = ($MaxSessions -replace '[^0-9]', '')

    If ($DesiredValue -ne $MaxSessionsCurrentValue -and $MaxSessionsCurrentValue -gt "1") {
        # Stop GP service
        Stop-Service $ServiceName
        # Remove gps.max.sessions from config file
        if (test-path -Path $Path) {
            ((Get-Content $Path) | Where-Object {$_ -notmatch 'gps.max.sessions' } | Set-Content $Path)
        }
    } 
    If ($DesiredValue -ne $MaxSessionsCurrentValue) {
        # Stop GP service (if not stopped in previous check)
        Stop-Service $ServiceName
        
        # Append new gps.max.sessions setting to file
        if (test-path -Path $Path) {
            write-host "setting gps.maxsessions to $DesiredValue on $Computer" -ForegroundColor Green
            Add-Content $Path "`ngps.max.sessions=$DesiredValue"
            }
        Start-Service $ServiceName
    } else { write-host "No changes made on $Computer" -ForegroundColor Yellow}
}

# Get credentials if other user is set to true
if ($OtherUser -eq $true) { $Cred = Get-Credential }

# loop scriptblock on each server
ForEach ($Computer in $Farm)
{
     Try
         {
             if ($OtherUser -ne $true) { Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $DesiredValue, $Path, $Computer, $ServiceName -ErrorAction Stop }
             else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $DesiredValue, $Path, $Computer, $ServiceName -Credential $Cred -ErrorAction Stop
             }
         }
     Catch
         {
             write-host "Something went wrong on computer $Computer" -ForegroundColor Red
         }
}
