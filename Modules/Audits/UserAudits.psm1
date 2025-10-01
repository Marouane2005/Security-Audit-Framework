function Invoke-UserAudit {
    [CmdletBinding()]
    param([Parameter(Mandatory=$false)][switch]$QuickMode)
    
    $results = @()
    Write-Host "  [*] Checking local administrators..." -ForegroundColor Gray
    
    try {
        $adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
        $adminCount = ($adminGroup | Measure-Object).Count
        if ($adminCount -gt 3) {
            $results += New-AuditResult -CheckName "Administrator Count" -Category "User & Privileges" -Status "WARNING" -Message "Too many administrators ($adminCount accounts)" -Severity 7 -Remediation "Review and remove unnecessary admin accounts"
        } else {
            $results += New-AuditResult -CheckName "Administrator Count" -Category "User & Privileges" -Status "PASS" -Message "Admin group size is appropriate ($adminCount)" -Severity 2 -Remediation "N/A"
        }
    } catch {
        $results += New-AuditResult -CheckName "Administrator Check" -Category "User & Privileges" -Status "INFO" -Message "Unable to enumerate administrators" -Severity 1 -Remediation "N/A"
    }
    
    Write-Host "  [*] Checking Guest account..." -ForegroundColor Gray
    try {
        $guestAccount = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        if ($null -ne $guestAccount -and $guestAccount.Enabled) {
            $results += New-AuditResult -CheckName "Guest Account" -Category "User & Privileges" -Status "FAIL" -Message "Guest account is ENABLED" -Severity 9 -Remediation "Disable-LocalUser -Name Guest"
        } else {
            $results += New-AuditResult -CheckName "Guest Account" -Category "User & Privileges" -Status "PASS" -Message "Guest account is disabled" -Severity 2 -Remediation "N/A"
        }
    } catch {
        $results += New-AuditResult -CheckName "Guest Account" -Category "User & Privileges" -Status "INFO" -Message "Guest account not found" -Severity 1 -Remediation "N/A"
    }
    
    Write-Host "  [*] Checking password policy..." -ForegroundColor Gray
    $passwordPolicy = Get-PasswordPolicy
    if ($null -ne $passwordPolicy) {
        if ($passwordPolicy.MinPasswordLength -ge 8) {
            $results += New-AuditResult -CheckName "Password Length" -Category "User & Privileges" -Status "PASS" -Message "Min password length: $($passwordPolicy.MinPasswordLength)" -Severity 2 -Remediation "N/A"
        } else {
            $results += New-AuditResult -CheckName "Password Length" -Category "User & Privileges" -Status "FAIL" -Message "Password length too short: $($passwordPolicy.MinPasswordLength)" -Severity 8 -Remediation "Set minimum to 8+: net accounts /minpwlen:8"
        }
    }
    
    return $results
}
Export-ModuleMember -Function Invoke-UserAudit
