param (
    [string]$ServerName,
    [string]$Operation,
    [string]$ServiceName
)

# Function to restart IIS
function Restart-IIS {
    try {
        Invoke-Command -ComputerName $ServerName -ScriptBlock {
            Stop-Service -Name W3SVC -Force
            Start-Service -Name W3SVC
            Write-Host "IIS restarted successfully on $using:ServerName"
        }
    } catch {
        Write-Host "Failed to restart IIS on $ServerName. Error: $_"
    }
}

# Function to restart a specified Windows service
function Restart-Service {
    param (
        [string]$ServiceName
    )
    
    try {
        Invoke-Command -ComputerName $ServerName -ScriptBlock {
            param($ServiceName)
            Stop-Service -Name $ServiceName -Force
            Start-Service -Name $ServiceName
            Write-Host "$ServiceName restarted successfully on $using:ServerName"
        } -ArgumentList $ServiceName
    } catch {
        Write-Host "Failed to restart service $ServiceName on $ServerName. Error: $_"
    }
}

# Validate operation and call appropriate function
switch ($Operation.ToLower()) {
    'iis' {
        Restart-IIS
    }
    'service' {
        if (-not [string]::IsNullOrWhiteSpace($ServiceName)) {
            Restart-Service -ServiceName $ServiceName
        } else {
            Write-Host "Service name is required for the service operation."
        }
    }
    default {
        Write-Host "Invalid operation specified. Use 'iis' or 'service'."
    }
}
