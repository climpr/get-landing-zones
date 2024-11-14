[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string[]]
    $RootLandingZonesPath,

    [Parameter(Mandatory = $false)]
    [string]
    $Pattern,
    
    [Parameter(Mandatory = $false)]
    [bool]
    $FilterOnChangedFiles = $false,

    [Parameter(Mandatory = $false)]
    [array]
    $ChangedFiles = @()
)

Write-Debug "Get-LandingZones.ps1: Started."
Write-Debug "Input parameters: $($PSBoundParameters | ConvertTo-Json -Depth 3)"

#* Establish defaults
$scriptRoot = $PSScriptRoot
Write-Debug "Working directory: '$((Resolve-Path -Path .).Path)'."
Write-Debug "Script root directory: '$(Resolve-Path -Relative -Path $scriptRoot)'."

#* Test paths
$validDirectories = foreach ($path in $RootLandingZonesPath) {
    if (Test-Path $path) {
        $path
    }
    else {
        Write-Debug "Path not found. $path. Skipping."
    }
}

$landingZones = @(Get-ChildItem $validDirectories -File -Recurse `
    | Where-Object { $_.Name -eq "metadata.json" } `
    | Select-Object -ExpandProperty Directory)
Write-Debug "Found $($landingZones.Count) landing zones."

$landingZoneObjects = foreach ($lz in $landingZones) {
    $lzRelativePath = Resolve-Path -Relative -Path $lz.FullName
    Write-Debug "[$($lz.Name)] Processing started."
    Write-Debug "[$($lz.Name)] Landing Zones directory path: '$lzRelativePath'."

    #* Resolve Landing Zone name
    $lzName = $lz.Name

    #* Set default state
    $landingZoneObject = @{
        Name            = $lzName
        LandingZonePath = $lzRelativePath
        Deploy          = $true
    }

    #* Exclude .examples Landing Zones
    if ($lzName -in @("example", "examples", ".example", ".examples")) {
        Write-Debug "[$lzName]. Skipped. Is example Landing Zone."
        continue
    }

    #* Resolve modified state
    if ($FilterOnChangedFiles) {
        Write-Debug "[$lzName] Checking if any Landing Zone files have been modified."
        $modified = $false
        foreach ($changedFile in $changedFiles) {
            if (!(Test-Path $changedFile)) {
                continue
            }
            if ($modified) {
                break
            }
            $modified = $changedFile.StartsWith("$lzRelativePath/")
        }
        
        if ($modified) {
            Write-Debug "[$lzName] At least one of the files used by the Landing Zone have been modified. Landing Zone included."
        }
        else {
            $landingZoneObject.Deploy = $false
            Write-Debug "[$lzName] No files used by the Landing Zone have been modified. Landing Zone not included."
        }
    }
    else {
        Write-Debug "[$lzName] Skipping modified files check due to parameter. FilterOnChangedFiles parameter set to [$false]. Landing Zone included."
    }

    #* Filter based on pattern
    if ($landingZoneObject.Deploy) {
        Write-Debug "[$lzName] Checking if Landing Zone matches pattern filter."
        if ($Pattern) {
            if ($lzName -match $Pattern) {
                Write-Debug "[$lzName] Pattern [$Pattern] matched successfully. Landing Zone included."
            }
            else {
                $landingZoneObject.Deploy = $false
                Write-Debug "[$lzName] Pattern [$Pattern] did not match. Landing Zone not included."
            }
        }
        else {
            Write-Debug "[$lzName] No pattern specified. Landing Zone included."
        }
    }
    else {
        Write-Debug "[$lzName] Skipping pattern check. Landing Zone already not included."
    }
            
    #* No filter met, adding
    Write-Debug "[$lzName] landingZoneObject: $($landingZoneObject | ConvertTo-Json -Depth 1)"
    $landingZoneObject
}

#* Print Landing Zones results to console
if (!$Quiet) {
    Write-Host "*** Landing Zones that are omitted ***"
    $omitted = @($landingZoneObjects | Where-Object { !$_.Deploy })
    if ($omitted) {
        $omitted | ForEach-Object { Write-Host $_.LandingZonePath }
    }
    else {
        Write-Host "None"
    }

    Write-Host "---"
    Write-Host ""
    Write-Host "*** Landing Zones that are included ***"
    $included = @($landingZoneObjects | Where-Object { $_.Deploy })
    if ($included) {
        $included | ForEach-Object { Write-Host $_.LandingZonePath }
    }
    else {
        Write-Host "None"
    }
}

#* Return landingZoneObjects
$landingZoneObjects | Where-Object { $_.Deploy }

Write-Debug "Get-LandingZones.ps1: Completed"