###########################
# Edit the settings Below #
###########################
$Servers = ("GEMS-01.gdtest.loc") # List servers here. 
$OtherUser = $false # Set to $true for credentials to pop up.
$GoodDir = "c:\Good" # Not really relevant to fill in as this is always C:\Good. Don't enter the logs folder directly here. The script uses the base dir to find out where the logs folder is. This setting is irrelevant for GEMS.
$Product = "gems" # Set gc, gp or gems
$DumpLocation = "c:\templogs" # Location to dump the Zip. This may be an UNC path, however make sure you have access permissions with your service account.
$DaysToGet = "30"

# Build Scriptblock for remote injection
$ScriptBlock = {
# Fetch input params
Param
      (
        [String]$Computer,
        [String]$GoodDir,
        [String]$DaysToGet,
        [String]$Product,
        [String]$DumpLocation
      )
    #debug
    write-host "Currently targetting $Computer" -ForegroundColor Green
    
    $ServerName = $Computer

    # .Net function for zipping files
    function ZipFiles($zipfilename, $sourcedir)
    {
       Add-Type -Assembly System.IO.Compression.FileSystem
       $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
       [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
            $zipfilename, $compressionLevel, $false)
    }

    # Function to get GEMS folder dynamically
    Function GetGemsQuickStart {
        $GEMSregKey="HKLM:\Software\WOW6432Node\Good Technology\Good Enterprise Mobility Server"
        $GEMSBase = Get-ItemProperty -path $GEMSregKey -ErrorAction SilentlyContinue
        $GEMSBase = $GEMSBase.path
        $GemsBase = $GEMSBase+"Good Server Distribution"
        $GEMSQuickStartFolder = (Get-ChildItem $GEMSBase | ?{ $_.PSIsContainer } | Where {$_.name -match "gems-quickstart-*"} | Sort-Object name -Descending | Select-Object -First 1 | select fullname).fullname
        return $GEMSQuickStartFolder
    }


    # Getting GC/GP/GEMS log folder location
    if (($Product -eq "gc") -OR ($Product -eq "gp")) {
        $DataFile = (Get-Content $GoodDir"\"$Product".data") | Where-Object {$_ -match 'log.upload.dir' } 
        $LogDir = $DataFile.Replace('\:', ':').Replace('\\', '\').Replace('log.upload.dir=', '')
    } elseif ($Product -eq "gems") {
        $LogDirTemp = GetGemsQuickStart
        # Check for GEMS 2.1 or higher
        $regKey="HKLM:\Software\Good Technology\Good Enterprise Mobility Server\Version"
        $GemsVersion = Get-ItemProperty -path $regKey ProxyServer -ErrorAction SilentlyContinue
        If ($GemsVersion -ge "2.1") {
            $DataFile = (Get-Content $LogDirTemp"\etc\org.ops4j.pax.logging.cfg") | Where-Object {$_ -match 'log4j.appender.cef.appender.dir' } 
            $LogDir = $DataFile.Replace('\:', ':').Replace('\\', '\').Replace('log4j.appender.cef.appender.dir = ', '')
        } Else {
            $LogDir = $LogDirTemp+"\data\log"
        }
    } else { 
        Write-host "No valid product recognized with the input. Exiting!" -ForegroundColor Red
        Exit
    }

    If (!(Test-path $env:TEMP)) { write-host "No TEMP folder. Exiting!" -ForegroundColor Red
        exit
        }

    # Fetch hostname if none is set
    if (!$ServerName) { $ServerName = $env:COMPUTERNAME }

    # Build temp location
    $Templogs = ($env:TEMP+"\"+$Product+"_"+$ServerName)

    # Create working folder, exit if this fails
    Try {
        (New-Item $Templogs -ItemType directory) | Out-Null
        }
    Catch {
        Write-Host "Creation of working folder failed, exiting!"
        exit
        }

    # Copy files newer than DaysOld date
    foreach ($i in (Get-ChildItem $LogDir))
    {
        $DaysOld = (Get-Date).AddDays(-$DaysToGet)
        if ($i.CreationTime -gt $DaysOld)
        {
            (Copy-Item $i.FullName $Templogs)
        }
    }

    # Check if zip exists, if not zip temp
    If (!(Test-Path $DumpLocation"\"$Product"_"$ServerName".zip")) {
        ZipFiles $DumpLocation"\"$Product"_"$ServerName".zip" $Templogs
    } Else {
        Write-host "Zip file $DumpLocation"\"$Product"_"$ServerName".zip" already exists. Please remove the file and try again" -ForegroundColor Red
    }
    # Clean up temp
    (Remove-Item $Templogs -Force -Recurse)
}



# Get credentials if other user is set to true
if ($OtherUser -eq $true) { $Cred = Get-Credential }

# loop scriptblock on each server
ForEach ($Computer in $Servers)
{
     Try
         {
             if ($OtherUser -ne $true) { Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Computer, $GoodDir, $DaysToGet, $Product, $DumpLocation -ErrorAction Stop }
             else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Computer, $GoodDir, $DaysToGet, $Product, $DumpLocation  -Credential $Cred -ErrorAction Stop
             }
         }
     Catch
         {
             write-host "Something went wrong on computer $Computer" -ForegroundColor Red
         }
} 
