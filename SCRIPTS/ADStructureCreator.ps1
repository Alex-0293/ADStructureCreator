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
        New-ADOrganizationalUnit -name $OuName -Path $ParentPath
        $Ou = Get-ADOrganizationalUnit -Filter "name -eq $OuName" -SearchBase $ParentPath       
    }
    Else {        
        Add-ToLog -Message "Organization unit [$OuName] already exist in [$ParentPath]" -logFilePath $ScriptLogFilePath -Display -status "info" 
    }
    return $Ou.DistinguishedName
}


$res = Import-Module ActiveDirectory -PassThru -Force
if ($res) {
    $ORGRootPath = (Get-ADDomain).DistinguishedName
    $OuCompany   = Add-ADOrganizationalUnit $CompanyName $ORGRootPath
    $OuGROUPS    = Add-ADOrganizationalUnit "GROUPS" $OuCompany
    $OuACL       = Add-ADOrganizationalUnit "ACL" $OuGROUPS
                   Add-ADOrganizationalUnit  "DISABLED" $OuACL
    $OuAPP       = Add-ADOrganizationalUnit  "APP"  $OuGROUPS
                   Add-ADOrganizationalUnit  "DISABLED"  $OuAPP
    $OuDST       = Add-ADOrganizationalUnit  "DST"  $OuGROUPS
                   Add-ADOrganizationalUnit  "DISABLED"  $OuDST
    $OuSHD       = Add-ADOrganizationalUnit  "SHD"  $OuGROUPS
                   Add-ADOrganizationalUnit  "DISABLED"  $OuSHD
    $OuDEVICES   = Add-ADOrganizationalUnit  "DEVICES"  $OuCompany
    $OuDC        = Add-ADOrganizationalUnit  "DC"  $OuDEVICES
    ForEach ($Item in $Locations)
    {
        $OuLoc  = Add-ADOrganizationalUnit  $Item  $OuDC
                  Add-ADOrganizationalUnit  "DISABLED"  $OuLoc
    }
    $OuSERVERS = Add-ADOrganizationalUnit  "SERVERS"  $OuDEVICES
    ForEach ($Item in $Locations)
    {
        $OuLoc = Add-ADOrganizationalUnit  $Item  $OuSERVERS
                 Add-ADOrganizationalUnit  "DISABLED"  $OuLoc
    }
    $OuWORKSTATIONS = Add-ADOrganizationalUnit  "WORKSTATIONS"  $OuDEVICES
    ForEach ($Item in $Locations)
    {
        $OuLoc = Add-ADOrganizationalUnit  $Item  $OuWORKSTATIONS
                 Add-ADOrganizationalUnit  "DISABLED"  $OuLoc
    }
    $OuDEPARTMENTS = Add-ADOrganizationalUnit  "DEPARTMENTS" $OuCompany
    ForEach ($Item in $Departments)
    {
        $OuDEPS = Add-ADOrganizationalUnit  $Item $OuDEPARTMENTS
        ForEach ($Item1 in $Locations)
        {
                $OuLoc = Add-ADOrganizationalUnit  $Item1  $OuDEPS
                         Add-ADOrganizationalUnit  "DISABLED"  $OuLoc
        }
    }
}

################################# Script end here ###################################
. "$GlobalSettings\$SCRIPTSFolder\Finish.ps1"
