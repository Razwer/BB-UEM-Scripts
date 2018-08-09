# Edit
$GoodDir = "c:\Good" # Not really relevant to fill in as this is always C:\Good. Don't enter the logs folder directly here. The script uses the base dir to find out where the logs folder is. This setting is irrelevant for GEMS.
$Product = "gems" # Set gc, gp or gems
$DumpLocation = "c:\logfiles" # Location to dump the Zip
$DaysToGet = "30"

# Don't edit
# GEMS install reg key
$GEMSregKey="HKLM:\Software\WOW6432Node\Good Technology\Good Enterprise Mobility Server"
$GEMSBase = Get-ItemProperty -path $GEMSregKey -ErrorAction SilentlyContinue
$GEMSBase = $GEMSBase.path


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
    $GEMSBaseRoot = $GEMSBase.path
    if (!$GEMSBaseRoot) {
        $GEMSregKey="HKLM:\Software\Good Technology\Good Enterprise Mobility Server"
        $GEMSBase = Get-ItemProperty -path $GEMSregKey -ErrorAction SilentlyContinue
        $GEMSBaseRoot = $GEMSBase.path       
        }
    $GEMSQuickStartFolder = (Get-ChildItem $GEMSBaseRoot"\Good Server Distribution"  | ?{ $_.PSIsContainer }| Where {$_.name -match "gems-quickstart-*"} | Sort-Object name -Descending | Select-Object -First 1 | select fullname).fullname
    return $GEMSQuickStartFolder
}


# Getting GC/GP/GEMS log folder location
if (($Product -eq "gc") -OR ($Product -eq "gp")) {
    if ($Product -eq "gc") { $ConfigFile = $GoodDir+"\gc.data" } else { ($ConfigFile = $GoodDir+"\gps.properties" ) }
    $DataFile = (Get-Content $ConfigFile) | Where-Object {$_ -match 'log.upload.dir' } 
    $LogDir = $DataFile.Replace('\:', ':').Replace('\\', '\').Replace('log.upload.dir=', '')
} elseif ($Product -eq "gems") {
    $LogDirTemp = GetGemsQuickStart
    # Check for GEMS 2.1 or higher
    $regKey="HKLM:\Software\Good Technology\Good Enterprise Mobility Server"
    $GemsVersion = Get-ItemProperty -path $regKey -ErrorAction SilentlyContinue
    If ($GemsVersion.version -ge "2.1") {
        $DataFile = (Get-Content $LogDirTemp"\etc\org.ops4j.pax.logging.cfg") | Where-Object {$_ -match 'log4j.appender.cef.appender.dir' } 
        $LogDir = $DataFile.Replace('\:', ':').Replace('\\', '\').Replace('log4j.appender.cef.appender.dir = ', '')
    } Else {
        $LogDir = $LogDirTemp+"\data\log"
    }
} else { 
    Write-host "No valid product recognized with the input. Exiting!" -ForegroundColor Red
    Exit
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