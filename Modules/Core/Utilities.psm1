function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-AuditResult {
    [CmdletBinding()]
    param(
        [string]$CheckName,
        [string]$Category,
        [ValidateSet("PASS","FAIL","WARNING","INFO")]
        [string]$Status,
        [string]$Message,
        [int]$Severity = 1,
        [string]$Remediation = "N/A"
    )
    
    return [PSCustomObject]@{
        CheckName = $CheckName
        Category = $Category
        Status = $Status
        Message = $Message
        Severity = $Severity
        Remediation = $Remediation
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Get-AuditSummary {
    [CmdletBinding()]
    param([array]$Results)
    
    $passed = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
    $failed = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
    $warnings = ($Results | Where-Object { $_.Status -eq "WARNING" }).Count
    $total = $Results.Count
    
    $riskScore = ($Results | Where-Object { $_.Status -eq "FAIL" } | Measure-Object -Property Severity -Sum).Sum
    
    return @{
        TotalChecks = $total
        Passed = $passed
        Failed = $failed
        Warnings = $warnings
        RiskScore = $riskScore
    }
}

function Test-RegistryValue {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Name,
        $ExpectedValue = $null
    )
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $value) {
                $actualValue = $value.$Name
                return @{
                    Exists = $true
                    Value = $actualValue
                    Match = if ($null -ne $ExpectedValue) { $actualValue -eq $ExpectedValue } else { $null }
                }
            }
        }
        return @{ Exists = $false; Value = $null; Match = $false }
    } catch {
        return @{ Exists = $false; Value = $null; Match = $false }
    }
}

function Test-PortOpen {
    [CmdletBinding()]
    param([int]$Port)
    
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
        return $connection
    } catch {
        return $false
    }
}

function Get-PasswordPolicy {
    try {
        $policy = net accounts
        $minLength = ($policy | Select-String "Minimum password length" | Out-String).Split(':')[1].Trim()
        $lockout = ($policy | Select-String "Lockout threshold" | Out-String).Split(':')[1].Trim()
        
        return @{
            MinPasswordLength = [int]$minLength
            LockoutThreshold = [int]$lockout
        }
    } catch {
        return $null
    }
}

Export-ModuleMember -Function *
