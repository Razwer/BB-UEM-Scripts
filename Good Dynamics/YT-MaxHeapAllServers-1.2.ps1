###################################################
# GC / GP MaxHeap Size for all servers            #
# Created by Yoni Toorenspits                     #
#                                                 #
# Version 1.2                                     #
# Released Jan 13th 2016                          #
#                                                 #
#######################################################################################################################
#                                                                                                                     #
# This script may be freely used, distributed, shared and altered with credits to the original author or contributors #
# (re)selling is strictly prohibited.                                                                                 #
# Distributing, sharing and using without credits to the original authors or contributors is strictly prohibited      #
# ©2016 Yoni Toorenspits                                                                                              #
#######################################################################################################################

# Cleanup Max Heap var in case script is used multiple times (i.e. first GC and GP after that.)
if ($MaxHeap) { Clear-Variable MaxHeap -Scope global }

###########################
# Edit the settings Below #
###########################
$Product = "GP" # Use either GC or GP
$Servers = ("SERVER01.DOMAIN.LOCAL","SERVER02.DOMAIN.LOCAL") # List servers here. Don't mix GP and GC. Servers should be all same specs. If not don't use this script!
$OtherUser = $false # Set to $true for credentials to pop up.
#$MaxHeap = "1234" # Uncomment to use static Heap Size. Comment out to use Good Sizing guide recommended forumla. Use static for combined role servers.

# Don't edit this
$Multiplier = $Servers.count

# Build Scriptblock for remote injection
$ScriptBlock = {
 # Fetch input params
 Param
      (
        [String]$Computer,
        [String]$Product,
        [Int]$Multiplier,
        [Int]$MaxHeap
      )
    #debug
    write-host "Currently targetting $Computer" -ForegroundColor Green

    # Detect Product and set registry value for product
    If ($Product -eq "GC") { 
        $RegKey = "HKLM:\SOFTWARE\WOW6432Node\Apache Software Foundation\Procrun 2.0\GoodControl\Parameters\Java" 
        $ServiceName = "GoodControl"
        }
    If ($Product -eq "GP") { 
        $RegKey = "HKLM:\SOFTWARE\WOW6432Node\Apache Software Foundation\Procrun 2.0\GPS\Parameters\Java" 
        $ServiceName = "GPS"
        }

    # Get current values
    $GCRegQuery = Get-ItemProperty $RegKey
    $GCJvMS = $GCRegQuery.JvmMs
    $GCJvMx = $GCRegQuery.JvmMx

    # Don't run if Max Heap size is static
    If (!$MaxHeap) {

        # Fetch current ram in MB and clean any non-numeric characters from the string
        $MachineRam = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
        $MachineRam = ($MachineRam -replace '[^0-9]', '')

        $ComputerName = $Computer
        #Get processors information            
        $CPU=Get-WmiObject -ComputerName $ComputerName -class Win32_Processor
        #Get Computer model information
        $OS_Info=Get-WmiObject -ComputerName $ComputerName -class Win32_ComputerSystem
            
     
        #Reset number of cores and use count for the CPUs counting
        $CPUs = 0
        $Cores = 0
           
        foreach($Processor in $CPU){
            $CPUs = $CPUs+1   
            #count the total number of cores         
            $Cores = $Cores+$Processor.NumberOfCores
            }

        $CoresCount = ($cores * $Multiplier)

        # Calculate max heap size on gathered information
        If ($CoresCount  -ge "8" -and $MachineRam -ge "5120") { $MaxHeap = "4096" } 
        ElseIf ($CoresCount  -ge "6" -and $MachineRam -ge "3072") { $MaxHeap = "2048" } 
        ElseIf ($CoresCount  -ge "4" -and $MachineRam -ge "2048") { $MaxHeap = "1024" } 
        Else { $MaxHeap = "640" } 
    }

    # Check if Max Heap is already desired value
    if ($GCJvMS -ne $MaxHeap) {
        #debug
        write-host "Changing Max Heap size on $ComputerName from $GCJvMS to $MaxHeap" -ForegroundColor Yellow

        Stop-Service $ServiceName
        $RegItem = "JvmMs"
        New-ItemProperty -Path $RegKey -Name $RegItem -Value $MaxHeap -PropertyType DWORD -Force | Out-Null
        $RegItem = "JvmMx"
        New-ItemProperty -Path $RegKey -Name $RegItem -Value $MaxHeap -PropertyType DWORD -Force | Out-Null
        Start-Service $ServiceName

        } Else {
        #debug
        Write-Host "No Changes Made to Heap Size on $ComputerName. Values were already correct. Current Value is $MaxHeap" -ForegroundColor Green

        }
}

# Get credentials if other user is set to true
if ($OtherUser -eq $true) { $Cred = Get-Credential }

# loop scriptblock on each server
ForEach ($Computer in $Servers)
{
     Try
         {
             if ($OtherUser -ne $true) { Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Computer, $Product, $Multiplier, $MaxHeap -ErrorAction Stop }
             else {
                Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -ArgumentList $Computer, $Product, $Multiplier,$MaxHeap -Credential $Cred -ErrorAction Stop
             }
         }
     Catch
         {
             write-host "Something went wrong on computer $Computer" -ForegroundColor Red
         }
}
