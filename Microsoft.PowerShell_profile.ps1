$currentDir = "C:\Users\$env:USERNAME\Documents\WindowsPowerShell"
$loadModules = "$currentDir\mods\ToLoad.json"
$numLoadedModules = 0

if (Test-Path $loadModules) {
    # Read JSON content and convert to PowerShell object
    $modulesData = Get-Content $loadModules -Raw | ConvertFrom-Json

    # Iterate over each module key in the JSON object
    foreach ($moduleName in $modulesData.PSObject.Properties.Name) {
        # Only load if "Load" property is true
        if ($modulesData.$moduleName.Load -eq $true) {
            $modulePath = "$currentDir\mods\$moduleName\$moduleName.psm1"

            if (Test-Path $modulePath) {
                try {
                    Import-Module $modulePath -Force -ErrorAction Stop
                    Write-Host "Loaded module: $moduleName"
                    $numLoadedModules++
                } catch {
                    Write-Warning "Failed to load module ${moduleName}: $_"
                }
            } else {
                Write-Warning "Module path not found: $modulePath"
            }
        } else {
        }
    }
} else {
    Write-Warning "Modules file not found: $loadModules"
}

Write-Host "Loaded $numLoadedModules modules." -ForegroundColor Green

function load {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-Not (Test-Path $loadModules)) {
        Write-Error "Modules file not found."
        return
    }

    $modulesData = Get-Content $loadModules -Raw | ConvertFrom-Json

    if (-Not $modulesData.PSObject.Properties.Name -contains $Name) {
        Write-Error "Module '$Name' is not listed in the modules JSON."
        return
    }

    if ($modulesData.$Name.Load -eq $true) {
        Write-Warning "Module '$Name' is already marked as loaded."
        return
    }

    $modulePath = "$currentDir\mods\$Name\$Name.psm1"
    if (-Not (Test-Path $modulePath)) {
        Write-Error "Module path not found: $modulePath"
        return
    }

    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-Host "Loaded module: $Name" -ForegroundColor Green
        
        $numLoadedModules++

        # Update the JSON data object
        $modulesData.$Name.Load = $true
        $modulesData.$Name.WasLoaded = $true

        # Save updated JSON back to file
        $modulesData | ConvertTo-Json -Depth 5 | Set-Content $loadModules -Encoding UTF8
    } catch {
        Write-Warning "Failed to load module ${Name}: $_"
    }
}

function unload {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-Not (Test-Path $loadModules)) {
        Write-Error "Modules file not found."
        return
    }

    $modulesData = Get-Content $loadModules -Raw | ConvertFrom-Json

    if (-Not $modulesData.PSObject.Properties.Name -contains $Name) {
        Write-Warning "Module '$Name' is not listed in the modules JSON."
        return
    }

    if ($modulesData.$Name.Load -eq $false) {
        Write-Warning "Module '$Name' is not currently loaded."
        return
    }

    try {
        Remove-Module -Name $Name -Force -ErrorAction Stop
        Write-Host "Module $Name removed from current session" -ForegroundColor Green

        # Update JSON flags
        $modulesData.$Name.Load = $false
        $numLoadedModules--

        # Save updated JSON back to file
        $modulesData | ConvertTo-Json -Depth 5 | Set-Content $loadModules -Encoding UTF8

        Write-Host "Module $Name marked as unloaded in JSON." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to remove module ${Name}: $_"
    }
}

function get-loaded {
    param(
        [string]$type
    )

    if (-Not (Test-Path $loadModules)) {
        Write-Warning "Modules file not found: $loadModules"
        return
    }

    $modulesData = Get-Content $loadModules -Raw | ConvertFrom-Json

    # Get all loaded modules (Load = true)
    $loadedModules = @(
    $modulesData.PSObject.Properties |
    Where-Object { $_.Value.Load -eq $true } |
    Select-Object -ExpandProperty Name
)

    if ($type -eq "n") {
        if ($loadedModules.Count -eq 0) {
            Write-Host "No modules are currently loaded." -ForegroundColor Yellow
            return
        }

        $numLoadedModules = $loadedModules.Count
        Write-Host "Current number of loaded modules: $numLoadedModules" -ForegroundColor Blue

    } elseif ($type -eq "l") {
        if ($loadedModules.Count -eq 0) {
            Write-Host "No modules are currently loaded." -ForegroundColor Yellow
            return
        }

        # Print the loaded modules numbered
        for ($i = 0; $i -lt $loadedModules.Count; $i++) {
            Write-Host "$($i + 1). $($loadedModules[$i])"
        }
        Write-Host "Total number: $($loadedModules.Count)" -ForegroundColor Cyan
    } else {
        Write-Warning "Unknown type '$type'. Use 'n' for number or 'l' for list."
    }
}