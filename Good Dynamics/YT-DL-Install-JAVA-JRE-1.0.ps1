###################################################
# Download and install Java JRE (GEMS Pre-req)    #
# Created by Yoni Toorenspits                     #
# Log function by Johan Eikelenboom               #
# runProcess function by Jos Lieben               #
# test-IsAdmin function by Andy Arismendi         #
#                                                 #
# Version 1.0                                     #
# Released Jan 23th 2016                          #
#                                                 #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2016 Yoni Toorenspits, Johan Eikelenboom, Jos Lieben, Andy Arismendi                                               #
#######################################################################################################################

###########################
# Edit the settings Below #
###########################
$downloads = "C:\TMP\Java" # Temp folder for the Java JRE 64 exe installer. Change this to your source location.
$JavaExe = "java64.exe" # Name of the downloaded executable to be saved on location above
$LogFile = "c:\TMP\mylog.txt" # Name/location of log file for this script

# Don't edit this
$url = "http://www.java.com/en/download/manual.jsp" # Java JRE url. Don't change
$JavaBase = $env:PROGRAMFILES+"\Java"

# Functions

# Elevation check function
function Test-IsAdmin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    } catch {
        throw "Failed to determine if the current user has elevated privileges. The error was: '{0}'." -f $_
    }

    <#
        .SYNOPSIS
            Checks if the current Powershell instance is running with elevated privileges or not.
        .EXAMPLE
            PS C:\> Test-IsAdmin
        .OUTPUTS
            System.Boolean
                True if the current Powershell is elevated, false if not.
    #>
}

# Run process function
function runProcess ($cmd, $params) {
    $p = new-object System.Diagnostics.Process
    $p.StartInfo = new-object System.Diagnostics.ProcessStartInfo
    $exitcode = $false
    $p.StartInfo.FileName = $cmd
    $p.StartInfo.Arguments = $params
    $p.StartInfo.UseShellExecute = $False
    $p.StartInfo.RedirectStandardError = $True
    $p.StartInfo.RedirectStandardOutput = $True
    $p.StartInfo.WindowStyle = 1;
    $null = $p.Start()
    $p.WaitForExit()
    $output = $p.StandardOutput.ReadToEnd()
    $exitcode = $p.ExitCode
    $p.Dispose()
    $exitcode
    $output
}

# Log writer function
Function WriteLog ($Msg, [Switch]$ScreenOnly = $False) {
    $TimeStamp = Get-Date

    Switch -wildcard ($Msg) {
        "-START-"    { Write-Host "$TimeStamp - Starting $($MyInvocation.ScriptName) (Version: $(Get-Date (Get-ChildItem $MyInvocation.ScriptName).LastWriteTime -format "yyyy-MM-dd HH.mm"))" }
        "ERROR:*"    { Write-Host "$TimeStamp - $Msg" -ForegroundColor Red }
        "WARNING:*" { Write-Host "$TimeStamp - $Msg" -ForegroundColor Yellow }
        "OK:*"       { Write-Host "$TimeStamp - $Msg" -ForegroundColor Green }
        "DEBUG:*"    { If ($Debug) { Write-Host "$TimeStamp - $Msg" -ForegroundColor Cyan } }
        Default      { Write-Host "$TimeStamp - INFO: $Msg" }
        }
       
    If (!($ScreenOnly)) {
        Switch -wildcard ($Msg) {
            "-START-"    { $Msg = "$TimeStamp - Starting $($MyInvocation.ScriptName) (Version: $(Get-Date (Get-ChildItem $MyInvocation.ScriptName).LastWriteTime -format "yyyy-MM-dd HH.mm"))" }
            "ERROR:*"    { $Msg = "$TimeStamp - $Msg" }
            "WARNING:*" { $Msg = "$TimeStamp - $Msg" }
            "OK:*"       { $Msg = "$TimeStamp - $Msg" }
            "DEBUG:*"    { If ($Debug) { $Msg = "$TimeStamp - $Msg" } }
            Default      { $Msg = "$TimeStamp - INFO: $Msg" }
            }
             
    If ($Debug -and ($msg -match "Debug:")) { 
        $Msg | Out-File -FilePath $LogFile -Append
        } Else {
            If (!($msg -match "Debug:")) { 
                $Msg | Out-File -FilePath $LogFile -Append
                }
            }
       }
}



# Start (write to log)
Writelog "-START-"

# Check for elevated permissions

$AdminCheck = Test-IsAdmin
if ($AdminCheck -eq $false) { 
    Write-host "No elevated permissions. please run PowerShell as administrator and try again" -ForegroundColor Red
    writelog "ERROR: Script terminated on lack of elevated permissions"
    Exit
    }
Writelog "OK: Elevated permissions" 

if (!(Test-Path -Path $downloads))
{
	# Create folder (silent)
	Try {
        Write-Host "Creating folder $downloads" 
	    New-Item -ItemType Directory -Path $downloads | Out-Null
        }
    Catch {
        Write-Host "Can't create folder $downloads. Please check permissions and try again" -ForegroundColor Red
        writelog "ERROR: Script terminated. Can't create folder $downloads"
        Exit
        }
    Writelog "OK: Folder $Downloads created"
} Else {
    Writelog "OK: Folder $Downloads already exists"
}

$firsthit = Invoke-WebRequest -Uri $url
$secondhit = ($firsthit.Links | where {$_.innerHTML -eq "Windows Offline (64-bit)"} | select href)
$DownloadUrl = $secondhit.href

Try {
    Invoke-WebRequest -uri $DownloadUrl -OutFile $downloads"\"$javaexe
    }
Catch {
    Write-host "Download of $DownloadUrl failed!" -ForegroundColor Red
    Writelog "ERROR: Script terminated. Download of $DownloadUrl failed!"
    Exit
    }
Writelog "OK: Download of $DownloadUrl succeeded"

# Fabricate path of downloaded exe for installation
$JavaInstaller = $downloads+"\"+$JavaExe

# Install Java JRE
#write-host "Currently running installer: $JavaInstaller" -ForegroundColor Green
Try {
    $res = runProcess $JavaInstaller "/s INSTALL_SILENT=1 STATIC=0 AUTO_UPDATE=0 WEB_JAVA=1 WEB_JAVA_SECURITY_LEVEL=H WEB_ANALYTICS=0 EULA=0 REBOOT=0 NOSTARTMENU=0 SPONSORS=0"
    }
Catch {
    write-host "Installer $JavaInstaller failed!" -ForegroundColor Red
    Writelog "ERROR: Script Terminated. Installer $JavaInstaller failed!"
    Exit
    }
$JavaDir1 = Get-ChildItem $JavaBase
$JavaDir2 = ($JavaDir1 | where {$_.name -like "jre*"} | Sort-Object name -descending | select name)
$JavaDir = $JavaDir2.name
if ($JavaDir.count -gt 1) {
    $JavaDir = $JavaDir[0]
}

# Fabricate JRE install dir
$JREDir = $JavaBase+"\"+$JavaDir

# Set or update environment vars and path
Try {
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $JREDir, "Machine")
    [System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";$JREDir\bin", "Machine")
    }
Catch {
    Write-host "failed to set JAVA_HOME and/or updating PATH" -ForegroundColor Red
    writelog "ERROR: Script Terminated. failed to set JAVA_HOME and/or updating PATH"
    Exit
    }
writelog "OK: Successfully installed"