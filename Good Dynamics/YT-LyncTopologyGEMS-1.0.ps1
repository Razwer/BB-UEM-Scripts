###################################################
# Create Lync GEMS Trusted AppPools (GEMS Pre-req)#
# Created by Yoni Toorenspits                     #
#                                                 #
# Version 1.0                                     #
# Released Jan 23th 2016                          #
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
$LyncPool = "lyncpool.contoso.com" # Lync pool of Lync environment of Customer
$LyncSite = "1" # Site id of Lync pool we are targetting in var above. use Get-CsSite to find the ID you need.
$GemsServers = ("gems001.contoso.local","gems002.contoso.local") # array of all Gems servers for Connect and Presence
$GemsTrustedPoolName = "pool_GEMS.contoso.local" # Define name for Good GEMS Trusted Application Pool within Lync Topology
$AppIDConnect = "appid_connect.contoso.local" # Define underlying app id of Connect service for Trusted Application Pool mentioned above
$AppIDPresence = "appid_presence.contoso.local" # Define underlying app id of Presence service for Trusted Application Pool mentioned above
$SipDomain = "@contoso.com" # Change to SIP domain used by apppool.

# Don't edit this
$FirstGems = $GemsServers | Select-Object -first 1 # Filter out first Gems server in array.

New-CsTrustedApplicationPool -Force -Identity $GemsTrustedPoolName -Registrar $LyncPool -RequiresReplication $false -Site $LyncSite -ComputerFqdn $FirstGems
New-CsTrustedApplication -Force -ApplicationId $AppIDConnect -TrustedApplicationPoolFqdn $GemsTrustedPoolName -Port 49555
New-CsTrustedApplication -Force -ApplicationId $AppIDPresence -TrustedApplicationPoolFqdn $GemsTrustedPoolName -Port 49777

#Building of SIP address of Presence.
$sip = "sip:presence_"+$FirstGems+$SipDomain
New-CsTrustedApplicationEndpoint -ApplicationId $AppIDPresence -TrustedApplicationPoolFqdn $GemsTrustedPoolName -SipAddress $sip

# Remaining GEMS servers
Foreach ($GemsServer in $GemsServers) {
	if ($GemsServer -ne $FirstGems) {
		New-CsTrustedApplicationComputer -Identity $GemsServer -Pool $GemsTrustedPoolName
		
        $sip = "sip:presence_"+$GemsServer+$SipDomain
        New-CsTrustedApplicationEndpoint -ApplicationId $AppIDPresence -TrustedApplicationPoolFqdn $GemsTrustedPoolName -SipAddress $sip
	}
}

# Uncomment to apply the topology right away
#Enable-CsTopology