# Rename this file to Settings.ps1
######################### value replacement #####################
[string] $Global:CompanyName           = ""         
[array]  $Global:OfficeLocations       = ""         
[array]  $Global:Departments           = ""         
[string] $Global:DefaultUserPassword   = ""         
[array]  $Global:DepartmentsWithLimits = @()         # Limit number of department employee in percents. Overall 100%.

######################### no replacement ########################
[bool]  $Global:GenerateUsers = $true
[bool]  $Global:UniqueNames = $True
[int]   $Global:UsersCount  = 20
[array] $Global:MaleNames   = "James", "John",     "Robert",   "Michael", "William",   "David",   "Richard", "Joseph",  "Thomas",    "Charles", "Christopher", "Daniel",   "Matthew", "Anthony", "Donald",    "Mark",   "Paul",   "Steven",   "Andrew",   "Kenneth"
[array] $Global:FemaleNames = "Mary",  "Patricia", "Jennifer", "Linda",   "Elizabeth", "Barbara", "Susan",   "Jessica", "Sarah",     "Karen",   "Nancy",       "Margaret", "Lisa",    "Betty",   "Dorothy",   "Sandra", "Ashley", "Kimberly", "Donna",    "Emily"
[array] $Global:Surname     = "Smith", "Johnson",  "Williams", "Brown",   "Jones",     "Miller",  "Davis",   "Garcia",  "Rodriguez", "Wilson",  "Martinez",    "Anderson", "Taylor",  "Thomas",  "Hernandez", "Moore",  "Martin", "Jackson",  "Thompson", "White"

[bool] $Global:LocalSettingsSuccessfullyLoaded  = $true
# Error trap
    trap {
        $Global:LocalSettingsSuccessfullyLoaded = $False
        exit 1
    }
