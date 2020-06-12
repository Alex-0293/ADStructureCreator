<#
    .NOTE
        .AUTHOR AlexK (1928311@tuta.io)
        .DATE   11.06.2020
        .VER    1
        .LANG   En
        
    .LINK
        https://github.com/Alex-0293/ADStructureCreator.git
    
    .COMPONENT
        Module: AlexkUtils                   ( https://github.com/Alex-0293/PS-Modules ) 
        Init, finish scripts: GlobalSettings ( https://github.com/Alex-0293/GlobalSettings )

    .SYNOPSIS 

    .DESCRIPTION
        Create typical AD structure 

    .PARAMETER

    .EXAMPLE
        ADStructureCreator.ps1

#>
Param (
    [Parameter( Mandatory = $false, Position = 0, HelpMessage = "Initialize global settings." )]
    [bool] $InitGlobal = $true,
    [Parameter( Mandatory = $false, Position = 1, HelpMessage = "Initialize local settings." )]
    [bool] $InitLocal  = $true   
)

$Global:ScriptInvocation = $MyInvocation
if ($env:AlexKFrameworkInitScript){
    . "$env:AlexKFrameworkInitScript" -MyScriptRoot (Split-Path $PSCommandPath -Parent) -InitGlobal $InitGlobal -InitLocal $InitLocal
} Else {
    Write-host "Environmental variable [AlexKFrameworkInitScript] does not exist!" -ForegroundColor Red
     exit 1
}
if ($LastExitCode) { exit 1 }

# Error trap
trap {
    if (get-module -FullyQualifiedName AlexkUtils) {
        Get-ErrorReporting $_
        . "$GlobalSettings\$SCRIPTSFolder\Finish.ps1" 
    }
    Else {
        Write-Host "[$($MyInvocation.MyCommand.path)] There is error before logging initialized. Error: $_" -ForegroundColor Red
    }   
    exit 1
}
################################# Script start here #################################
Function Add-ADOrganizationalUnit {
    param(
        [string] $OuName,
        [string] $ParentPath
    )
    
    $Ou = Get-ADOrganizationalUnit -Filter 'name -eq $OuName' -SearchBase $ParentPath
    if ( $null-eq $Ou ) {
        Add-ToLog -Message "Adding organization unit [$OuName] in [$ParentPath]." -logFilePath $ScriptLogFilePath -Display -status "info" 
        New-ADOrganizationalUnit -name $OuName -Path $ParentPath
        $Ou = Get-ADOrganizationalUnit -Filter 'name -eq $OuName' -SearchBase $ParentPath       
    }
    Else {        
        Add-ToLog -Message "Organization unit [$OuName] already exist in [$ParentPath]!" -logFilePath $ScriptLogFilePath -Display -status "error" 
    }
    return $Ou.DistinguishedName
}
Function New-User {
    
    $Sex = "Male", "Female" | Get-Random

    if ($Sex -eq "Male") {
        $GivenName = $Global:MaleNames |  Get-Random
        if ($Global:UniqueNames) {
            $Global:MaleNames = $Global:MaleNames | Where-Object {$_ -ne $GivenName}
        }
    }
    Else {
        $GivenName = $Global:FemaleNames | Get-Random
        if ($Global:UniqueNames) {
            $Global:FemaleNames = $Global:FemaleNames | Where-Object { $_ -ne $GivenName}
        }
    }
    
    $Surname = $Global:Surname1 | Get-Random
    if ($Global:UniqueNames) {
        $Global:Surname1 = $Global:Surname1 | Where-Object { $_ -ne $Surname }
    }

    
    if ($Global:DepartmentsWithLimits) {
        $Global:Limits = @()
        foreach ($Item in $Global:DepartmentsWithLimits.keys){
            $Departments = [PSCustomObject]@{
                Name    = $Item
                Percent = $Global:DepartmentsWithLimits.$Item
                Max     = [math]::Round($Global:UsersCount / 100 * $Global:DepartmentsWithLimits.$Item, 0)
                Count   = ($Global:users | Where-Object { $_.Department -eq $Item}).count
            }
            $Global:Limits += $Departments
        }
        
        do {
            $Department      = $Global:Departments | Get-Random
            $DepartmentLimit = $Global:Limits | Where-Object { $_.Name -eq $Department }
        } until ($DepartmentLimit.Count -lt $DepartmentLimit.Max)
        $DepartmentLimit.Count ++    
    }
    Else {
        $Department                       = $Global:Departments | Get-Random 
    }    
    $Initials                          = ($Global:Surname | Get-Random ).SubString(0,1)
    $Name                              = "$GivenName $Initials. $Surname"
    $DisplayName                       = "$GivenName $Initials. $Surname"
    $SamAccountName                    = "$GivenName.$Surname"
    $UserPassword                      = ConvertTo-SecureString $Global:DefaultUserPassword -AsPlainText -Force
    $Enabled                           = $true
    $ChangePasswordAtLogon             = $false
    $Company                           = $Global:CompanyName
    $AllowReversiblePasswordEncryption = $False
    $Division                          = $Global:OfficeLocations | Get-Random
    $OfficePhone                       = (1..3 | ForEach-Object {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0" | Get-Random}) -join ""
    $MobilePhone                       = "+$(Get-Random -Maximum 99) ($((1..3 | ForEach-Object { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" | Get-Random }) -join '')) $((1..7 | ForEach-Object { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" | Get-Random }) -join '')"
    $Title                             =  $Global:Title | Get-Random
    $Email                             = "$SamAccountName@$($Global:CompanyName).com"

    $User = [PSCustomObject]@{
        Sex                               = $Sex
        Name                              = $Name
        GivenName                         = $GivenName
        Surname                           = $Surname
        Department                        = $Department
        EmployeeID                        = $Global:EmployeeNumber
        DisplayName                       = $DisplayName
        SamAccountName                    = $SamAccountName
        AccountPassword                   = $UserPassword
        Enabled                           = $Enabled
        ChangePasswordAtLogon             = $ChangePasswordAtLogon
        Company                           = $Company
        AllowReversiblePasswordEncryption = $AllowReversiblePasswordEncryption
        Initials                          = $Initials
        Division                          = $Division
        OfficePhone                       = $OfficePhone
        MobilePhone                       = $MobilePhone
        Title                             = $Title 
        Email                             = $Email 
    }
    $Global:EmployeeNumber ++
    Return $User
}

if ($Global:GenerateUsers) {
    Add-ToLog -Message "Generating users." -logFilePath $ScriptLogFilePath -Display -status "info" 
    $Global:Surname1 = $Global:Surname
    [int] $Global:EmployeeNumber = 1
    $Global:users = @()

    for ($i = 1; $i -le $Global:UsersCount; $i++) {
        $Global:users += New-User
    }
    #$Global:users  | Select-Object EmployeeID, Sex, DisplayName, Department, SamAccountName, Company, Office, OfficePhone, MobilePhone  | Format-Table -AutoSize
    #$Global:Limits | Format-Table -AutoSize
    Add-ToLog -Message "Users generated." -logFilePath $ScriptLogFilePath -Display -status "info"
}

$res = Import-Module ActiveDirectory -PassThru -Force
if ($res) {  
    
    $ORGRootPath = (Get-ADDomain).DistinguishedName
    Add-ToLog -Message "Generating organization units in [$ORGRootPath]." -logFilePath $ScriptLogFilePath -Display -status "info"               
    $Global:ParentLevel ++
    $OuCompany   = Add-ADOrganizationalUnit $CompanyName $ORGRootPath
    $OuGROUPS    = Add-ADOrganizationalUnit "GROUPS" $OuCompany
    $OuACL       = Add-ADOrganizationalUnit "ACL" $OuGROUPS
    $Ou          = Add-ADOrganizationalUnit "DISABLED" $OuACL 
    $OuAPP       = Add-ADOrganizationalUnit "APP"  $OuGROUPS
    $Ou          = Add-ADOrganizationalUnit "DISABLED"  $OuAPP
    $OuDST       = Add-ADOrganizationalUnit "DST"  $OuGROUPS
    $Ou          = Add-ADOrganizationalUnit "DISABLED"  $OuDST
    $OuSHD       = Add-ADOrganizationalUnit "SHD"  $OuGROUPS
    $Ou          = Add-ADOrganizationalUnit "DISABLED"  $OuSHD
    $OuDEVICES   = Add-ADOrganizationalUnit "DEVICES"  $OuCompany
    $OuDC        = Add-ADOrganizationalUnit "DC"  $OuDEVICES
    ForEach ($Item in $Global:OfficeLocations)
    {
        $OuLoc  = Add-ADOrganizationalUnit $Item  $OuDC
        $Ou     = Add-ADOrganizationalUnit "DISABLED"  $OuLoc
    }
    $OuSERVERS = Add-ADOrganizationalUnit "SERVERS"  $OuDEVICES
    ForEach ($Item in $Global:OfficeLocations)
    {
        $OuLoc = Add-ADOrganizationalUnit $Item  $OuSERVERS
        $Ou    = Add-ADOrganizationalUnit "DISABLED"  $OuLoc
    }
    $OuWORKSTATIONS = Add-ADOrganizationalUnit "WORKSTATIONS"  $OuDEVICES
    ForEach ($Item in $Global:OfficeLocations)
    {
        $OuLoc = Add-ADOrganizationalUnit $Item  $OuWORKSTATIONS
        $Ou    = Add-ADOrganizationalUnit "DISABLED"  $OuLoc
    }
    $OuDEPARTMENTS = Add-ADOrganizationalUnit "DEPARTMENTS" $OuCompany
    ForEach ($Item in $Departments)
    {
        $OuDEPS = Add-ADOrganizationalUnit $Item $OuDEPARTMENTS
        ForEach ($Item1 in $Global:OfficeLocations)
        {
                $OuLoc = Add-ADOrganizationalUnit $Item1  $OuDEPS
                $Ou    = Add-ADOrganizationalUnit "DISABLED"  $OuLoc
        }
    }
    $Global:ParentLevel --
    Add-ToLog -Message "Generated organization units in [$ORGRootPath]." -logFilePath $ScriptLogFilePath -Display -status "info"               
}

if (-not $Global:GenerateUsers) {
    $Users = Import-Csv -Path $Global:UserCSVFilePath -Delimiter ";" 
}

Add-ToLog -Message "Adding users in AD." -logFilePath $ScriptLogFilePath -Display -status "info"               
$Global:ParentLevel ++
foreach ($User in $Users) {    
    if ($User.Enabled -eq "True"){
        $Enabled = $true
    }
    Else {
        $Enabled = $false
    }
    if ($User.ChangePasswordAtLogon -eq "True"){
        $ChangePasswordAtLogon = $true
    }
    Else {
        $ChangePasswordAtLogon = $false
    }
    if ($User.Department) {
        $Department      = $User.Department
        $Office          = $User.Division
        $DepartmentsPath = (Get-ADOrganizationalUnit -Filter 'name -eq "DEPARTMENTS"' -SearchBase $ORGRootPath).DistinguishedName
        $DepartmentPath  = (Get-ADOrganizationalUnit -Filter 'name -eq $Department' -SearchBase $DepartmentsPath).DistinguishedName
        $OfficePath      = (Get-ADOrganizationalUnit -Filter 'name -eq $Office' -SearchBase $DepartmentPath ).DistinguishedName
    }

    if ($OfficePath) {
        try {            
            Add-ToLog -Message "Adding user [$($User.DisplayName)] to [$Department] in [$Office]." -logFilePath $ScriptLogFilePath -Display -status "info"
            New-ADUser `
                -Name                  $User.Name `
                -GivenName             $User.GivenName `
                -Surname               $User.Surname `
                -Department            $User.Department `
                -State                 $User.State `
                -EmployeeID            $User.EmployeeID `
                -DisplayName           $User.DisplayName `
                -SamAccountName        $User.SamAccountName `
                -AccountPassword       $(ConvertTo-SecureString $User.AccountPassword -AsPlainText -Force) `
                -Enabled               $Enabled `
                -ChangePasswordAtLogon $ChangePasswordAtLogon `
                -Path                  $OfficePath `
                -Company               $User.Company `
                -AllowReversiblePasswordEncryption  $User.AllowReversiblePasswordEncryption `
                -Initials              $User.Initials `
                -Division              $User.Division `
                -OfficePhone           $User.OfficePhone `
                -MobilePhone           $User.MobilePhone `
                -Title                 $User.Title `
                -Email                 $User.Email 
        }
        Catch {
            Add-ToLog -Message "Error while adding user [$($User.DisplayName)] to [$Department] in [$Office]! $_" -logFilePath $ScriptLogFilePath -Display -status "error"
        }
    }
}
$Global:ParentLevel --
Add-ToLog -Message "Added users in AD." -logFilePath $ScriptLogFilePath -Display -status "info"               

################################# Script end here ###################################
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1"
