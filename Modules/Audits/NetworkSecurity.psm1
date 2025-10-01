function Invoke-NetworkSecurityAudit {
    [CmdletBinding()]
    param([Parameter(Mandatory=$false)][switch]$QuickMode)
    
    $results = @()
    Write-Host "  [*] Checking network shares..." -ForegroundColor Gray
    
    try {
        $shares = Get-SmbShare | Where-Object { $_.Name -notin @("ADMIN$", "IPC$", "C$") }
        if ($shares) {
            $shareNames = ($shares | Select-Object -ExpandProperty Name) -join ", "
            $results += New-AuditResult -CheckName "Network Shares" -Category "Network Security" -Status "WARNING" -Message "Active shares: $shareNames" -Severity 6 -Remediation "Review share permissions"
        } else {
            $results += New-AuditResult -CheckName "Network Shares" -Category "Network Security" -Status "PASS" -Message "No custom shares found" -Severity 2 -Remediation "N/A"
        }
    } catch {
        $results += New-AuditResult -CheckName "Network Shares" -Category "Network Security" -Status "INFO" -Message "Unable to enumerate shares" -Severity 1 -Remediation "N/A"
    }
    
    Write-Host "  [*] Checking RDP status..." -ForegroundColor Gray
    $rdpRegistry = Test-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
    if ($rdpRegistry.Exists -and $rdpRegistry.Value -eq 0) {
        $results += New-AuditResult -CheckName "Remote Desktop (RDP)" -Category "Network Security" -Status "WARNING" -Message "RDP is ENABLED" -Severity 6 -Remediation "Disable if not needed"
    } else {
        $results += New-AuditResult -CheckName "Remote Desktop (RDP)" -Category "Network Security" -Status "PASS" -Message "RDP is disabled" -Severity 2 -Remediation "N/A"
    }
    
    return $results
}
Export-ModuleMember -Function Invoke-NetworkSecurityAudit
