# Rename this file to Settings.ps1
######################### value replacement #####################
[string]  $Global:CompanyName     = ""         
[array]   $Global:OfficeLocations = ""         
[array]   $Global:Departments     = ""         




######################### no replacement ########################



[bool]  $Global:LocalSettingsSuccessfullyLoaded  = $true
# Error trap
    trap {
        $Global:LocalSettingsSuccessfullyLoaded = $False
        exit 1
    }
