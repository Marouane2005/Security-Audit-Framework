[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "Quick")]
    [string]$AuditType = "Full",
    
    [Parameter(Mandatory=$false)]
    [switch]$OpenReport
)

$ErrorActionPreference = "Continue"

Import-Module "$PSScriptRoot\Modules\Core\Utilities.psm1" -Force
Import-Module "$PSScriptRoot\Modules\Core\Reporter.psm1" -Force

$banner = @"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          🔒 SECURITY AUDIT FRAMEWORK v2.0 🔒                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

"@

Write-Host $banner -ForegroundColor Cyan

$isAdmin = Test-IsAdmin
if (-not $isAdmin) {
    Write-Host "⚠ WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "  Some checks will be limited`n" -ForegroundColor Yellow
} else {
    Write-Host "✓ Running with Administrator privileges`n" -ForegroundColor Green
}

Write-Host "Audit Type: $AuditType" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Cyan

$quickMode = $AuditType -eq "Quick"
$allResults = @()

$auditModules = @(
    @{Name="System"; Path="Modules\Audits\SystemSecurity.psm1"; Function="Invoke-SystemSecurityAudit"}
    @{Name="User"; Path="Modules\Audits\UserAudits.psm1"; Function="Invoke-UserAudit"}
    @{Name="Network"; Path="Modules\Audits\NetworkSecurity.psm1"; Function="Invoke-NetworkSecurityAudit"}
)

foreach ($module in $auditModules) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "Running $($module.Name) Audit..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray
    
    try {
        $modulePath = Join-Path $PSScriptRoot $module.Path
        Import-Module $modulePath -Force
        
        if ($quickMode) {
            $results = & $module.Function -QuickMode
        } else {
            $results = & $module.Function
        }
        $allResults += $results
        Write-Host ""
    } catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "Generating Report..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

$summary = Get-AuditSummary -Results $allResults

$auditData = @{
    Metadata = @{
        ComputerName = $env:COMPUTERNAME
        AuditDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        AuditType = $AuditType
        ExecutedBy = "$env:USERDOMAIN\$env:USERNAME"
        IsAdmin = $isAdmin
        FrameworkVersion = "2.0"
    }
    Summary = $summary
    Results = $allResults
}

$outputPath = "$PSScriptRoot\Reports"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFileName = "SecurityAudit_$($env:COMPUTERNAME)_$timestamp.html"
$reportPath = Join-Path $outputPath $reportFileName

$htmlReport = New-HTMLReport -AuditData $auditData
$htmlReport | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    AUDIT COMPLETE                            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total Checks: $($summary.TotalChecks)" -ForegroundColor White
Write-Host "  Passed:       $($summary.Passed) ✓" -ForegroundColor Green
Write-Host "  Failed:       $($summary.Failed) ✗" -ForegroundColor Red
Write-Host "  Warnings:     $($summary.Warnings) ⚠" -ForegroundColor Yellow
Write-Host "  Risk Score:   $($summary.RiskScore)" -ForegroundColor $(if($summary.RiskScore -ge 150){"Red"}elseif($summary.RiskScore -ge 50){"Yellow"}else{"Green"})
Write-Host "`nReport saved to:" -ForegroundColor Cyan
Write-Host "  $reportPath`n" -ForegroundColor White

if ($OpenReport) {
    Start-Process $reportPath
}
