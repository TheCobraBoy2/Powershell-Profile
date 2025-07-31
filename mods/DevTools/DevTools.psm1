function touch {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    New-Item -Path $Name -ItemType File -Force | Out-Null
}

Export-ModuleMember -Function touch
