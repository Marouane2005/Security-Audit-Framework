function Invoke-SystemSecurityAudit {
    [CmdletBinding()]
    param([Parameter(Mandatory=$false)][switch]$QuickMode)
    
    $results = @()
    Write-Host "  [*] Checking Windows Defender status..." -ForegroundColor Gray
    
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($null -ne $defenderStatus) {
            if ($defenderStatus.AntivirusEnabled) {
                $results += New-AuditResult -CheckName "Windows Defender Enabled" -Category "System Security" -Status "PASS" -Message "Windows Defender is enabled" -Severity 3 -Remediation "N/A"
            } else {
                $results += New-AuditResult -CheckName "Windows Defender Enabled" -Category "System Security" -Status "FAIL" -Message "Windows Defender is DISABLED" -Severity 9 -Remediation "Enable Windows Defender in Windows Security"
            }
            
            if ($defenderStatus.RealTimeProtectionEnabled) {
                $results += New-AuditResult -CheckName "Real-Time Protection" -Category "System Security" -Status "PASS" -Message "Real-time protection is enabled" -Severity 3 -Remediation "N/A"
            } else {
                $results += New-AuditResult -CheckName "Real-Time Protection" -Category "System Security" -Status "FAIL" -Message "Real-time protection is DISABLED" -Severity 9 -Remediation "Enable in Windows Security settings"
            }
        }
    } catch {
        $results += New-AuditResult -CheckName "Windows Defender Status" -Category "System Security" -Status "WARNING" -Message "Unable to query Windows Defender" -Severity 5 -Remediation "Verify Windows Defender is installed"
    }
    
    Write-Host "  [*] Checking UAC settings..." -ForegroundColor Gray
    $uacRegistry = Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ExpectedValue 1
    if ($uacRegistry.Exists -and $uacRegistry.Match) {
        $results += New-AuditResult -CheckName "User Account Control (UAC)" -Category "System Security" -Status "PASS" -Message "UAC is enabled" -Severity 3 -Remediation "N/A"
    } else {
        $results += New-AuditResult -CheckName "User Account Control (UAC)" -Category "System Security" -Status "FAIL" -Message "UAC is DISABLED" -Severity 9 -Remediation "Enable UAC via Group Policy"
    }
    
    Write-Host "  [*] Checking firewall status..." -ForegroundColor Gray
    try {
        $firewallProfiles = Get-NetFirewallProfile
        $disabledProfiles = $firewallProfiles | Where-Object { -not $_.Enabled }
        if ($disabledProfiles) {
            $profileNames = ($disabledProfiles | Select-Object -ExpandProperty Name) -join ", "
            $results += New-AuditResult -CheckName "Windows Firewall" -Category "System Security" -Status "FAIL" -Message "Firewall DISABLED for: $profileNames" -Severity 10 -Remediation "Enable Windows Firewall for all profiles"
        } else {
            $results += New-AuditResult -CheckName "Windows Firewall" -Category "System Security" -Status "PASS" -Message "Firewall enabled for all profiles" -Severity 2 -Remediation "N/A"
        }
    } catch {
        $results += New-AuditResult -CheckName "Windows Firewall" -Category "System Security" -Status "WARNING" -Message "Unable to check firewall status" -Severity 6 -Remediation "Verify Windows Firewall service"
    }
    
    return $results
}
Export-ModuleMember -Function Invoke-SystemSecurityAudit
