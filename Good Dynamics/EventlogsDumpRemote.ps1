###########################
# Edit the settings Below #
###########################
$Servers = ("localhost") # List servers here. 
$OtherUser = $false # Set to $true for credentials to pop up.
$EntryType = ("error", "warning") # Enter which type of events you want
$DumpLocation = "c:\eventlogs" # Location to dump the CSV
$AmountOfDays = "180" # Amount of days to fetch from the eventlog

# Build Scriptblock for remote injection
$ScriptBlock = {
 # Fetch input params
 Param
      (
        [String]$Computer,
        [Array]$EntryType,
        [string]$AmountOfDays,
        [String]$DumpLocation
      )
    #debug
    write-host "Currently targetting $Computer" -ForegroundColor Green

    
    Function DumpEventlogs($EventLog,$EntryType,$Days) {
        $DaysToGet = (Get-Date).AddDays(-$Days)
        Get-Eventlog -logname $Eventlog -EntryType $EntryType -After $DaysToGet
    }

    Function DumpSystemLog($EntryType,$DumpLocation,$AmountOfDays){
        $Dumplogs = DumpEventlogs "system" $EntryType $AmountOfDays
        $DumpLogs | export-csv $DumpLocation"\"$ServerName"_System_"$EntryType".csv"
    }

    Function DumpApplicationLog($EntryType,$DumpLocation,$AmountOfDays){
        $Dumplogs = DumpEventlogs "application" $EntryType $AmountOfDays
        $DumpLogs | export-csv $DumpLocation"\"$ServerName"_Application_"$EntryType".csv"
    }

    Function DumpSecurityLog($EntryType,$DumpLocation,$AmountOfDays){
        $Dumplogs = DumpEventlogs "system" $EntryType $AmountOfDays
        $DumpLogs | export-csv $DumpLocation"\"$ServerName"_security_"$EntryType".csv"
    }
    
    # Script execution
    If (!$AmountOfDays) { $AmountOfDays = "90"}
    $ServerName = $Computer
    
    DumpApplicationLog $EntryType $DumpLocation $AmountOfDays
    DumpSystemLog $EntryType $DumpLocation $AmountOfDays
}



# Get credentials if other user is set to true
if ($OtherUser -eq $true) { $Cred = Get-Credential }

# loop scriptblock on each server
ForEach ($Computer in $Servers)
{
     Try
         {
             if ($OtherUser -ne $true) { Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Computer, $EntryType, $AmountOfDays, $DumpLocation -ErrorAction Stop }
             else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Computer, $EntryType, $AmountOfDays, $DumpLocation -Credential $Cred -ErrorAction Stop
             }
         }
     Catch
         {
             write-host "Something went wrong on computer $Computer" -ForegroundColor Red
         }
}