function New-HTMLReport {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][hashtable]$AuditData)
    
    $passCount = $AuditData.Summary.Passed
    $failCount = $AuditData.Summary.Failed
    $warnCount = $AuditData.Summary.Warnings
    $totalCount = $AuditData.Summary.TotalChecks
    $riskScore = $AuditData.Summary.RiskScore
    
    $riskLevel = "LOW"
    if ($riskScore -ge 150) { $riskLevel = "HIGH" }
    elseif ($riskScore -ge 50) { $riskLevel = "MEDIUM" }
    
    $passPercent = if ($totalCount -gt 0) { [math]::Round(($passCount / $totalCount) * 100, 1) } else { 0 }
    $failPercent = if ($totalCount -gt 0) { [math]::Round(($failCount / $totalCount) * 100, 1) } else { 0 }
    $warnPercent = if ($totalCount -gt 0) { [math]::Round(($warnCount / $totalCount) * 100, 1) } else { 0 }
    
    $categories = $AuditData.Results | Group-Object -Property Category
    $findingsHTML = ""
    
    foreach ($category in $categories) {
        $categoryName = $category.Name
        $findingsHTML += "<div class='category-section'><h3>$categoryName</h3><div class='findings-table'>"
        
        foreach ($result in $category.Group) {
            $statusClass = switch ($result.Status) {
                "PASS" { "status-pass" }
                "FAIL" { "status-fail" }
                "WARNING" { "status-warn" }
                default { "status-info" }
            }
            $statusIcon = switch ($result.Status) {
                "PASS" { "✓" }
                "FAIL" { "✗" }
                "WARNING" { "⚠" }
                default { "ℹ" }
            }
            $severityBadge = if ($result.Severity -ge 8) { "<span class='severity-badge severity-critical'>Critical</span>" }
            elseif ($result.Severity -ge 5) { "<span class='severity-badge severity-high'>High</span>" }
            elseif ($result.Severity -ge 3) { "<span class='severity-badge severity-medium'>Medium</span>" }
            else { "<span class='severity-badge severity-low'>Low</span>" }
            
            $findingsHTML += "<div class='finding-item'><div class='finding-header'><span class='$statusClass'>$statusIcon $($result.CheckName)</span>$severityBadge</div>"
            $findingsHTML += "<div class='finding-message'>$($result.Message)</div><div class='finding-remediation'><strong>Remediation:</strong> $($result.Remediation)</div>"
            $findingsHTML += "<div class='finding-timestamp'>$($result.Timestamp)</div></div>"
        }
        $findingsHTML += "</div></div>"
    }
    
    return @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Security Audit - $($AuditData.Metadata.ComputerName)</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Segoe UI',Tahoma,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);padding:20px;color:#333}
.container{max-width:1400px;margin:0 auto;background:white;border-radius:10px;box-shadow:0 10px 40px rgba(0,0,0,0.3);overflow:hidden}
.header{background:linear-gradient(135deg,#1e3c72 0%,#2a5298 100%);color:white;padding:40px;text-align:center}
.header h1{font-size:2.5em;margin-bottom:10px;text-shadow:2px 2px 4px rgba(0,0,0,0.3)}.header .subtitle{font-size:1.2em;opacity:0.9}
.metadata{background:#f8f9fa;padding:30px;display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px;border-bottom:3px solid #e9ecef}
.metadata-item{background:white;padding:15px;border-radius:8px;box-shadow:0 2px 5px rgba(0,0,0,0.1)}.metadata-item strong{display:block;color:#666;font-size:0.9em;margin-bottom:5px;text-transform:uppercase}
.metadata-item span{font-size:1.2em;color:#333;font-weight:600}.summary{padding:40px;background:white}.summary h2{color:#1e3c72;margin-bottom:30px;font-size:2em;border-bottom:3px solid #667eea;padding-bottom:10px}
.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:20px;margin-bottom:30px}
.stat-card{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;padding:25px;border-radius:10px;text-align:center;box-shadow:0 5px 15px rgba(0,0,0,0.2);transition:transform 0.3s}
.stat-card:hover{transform:translateY(-5px)}.stat-card.pass{background:linear-gradient(135deg,#28a745 0%,#20c997 100%)}
.stat-card.fail{background:linear-gradient(135deg,#dc3545 0%,#c82333 100%)}.stat-card.warn{background:linear-gradient(135deg,#ffc107 0%,#ff9800 100%)}
.stat-card.risk{background:linear-gradient(135deg,#6c757d 0%,#495057 100%)}.stat-number{font-size:3em;font-weight:bold;margin-bottom:10px}
.stat-label{font-size:1.1em;opacity:0.9}.stat-percent{font-size:0.9em;margin-top:5px;opacity:0.8}.findings{padding:40px;background:#f8f9fa}
.findings h2{color:#1e3c72;margin-bottom:30px;font-size:2em;border-bottom:3px solid #667eea;padding-bottom:10px}
.category-section{margin-bottom:40px;background:white;border-radius:10px;padding:25px;box-shadow:0 3px 10px rgba(0,0,0,0.1)}
.category-section h3{color:#1e3c72;font-size:1.5em;margin-bottom:20px;padding-bottom:10px;border-bottom:2px solid #e9ecef}
.findings-table{display:flex;flex-direction:column;gap:15px}.finding-item{background:#f8f9fa;padding:20px;border-radius:8px;border-left:4px solid #ccc;transition:all 0.3s}
.finding-item:hover{box-shadow:0 5px 15px rgba(0,0,0,0.1);transform:translateX(5px)}.finding-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;font-weight:600;font-size:1.1em}
.status-pass{color:#28a745}.status-fail{color:#dc3545}.status-warn{color:#ffc107}
.status-info{color:#17a2b8}.finding-message{color:#555;margin-bottom:10px;line-height:1.6}
.finding-remediation{background:white;padding:10px;border-radius:5px;margin-bottom:10px;font-size:0.95em;border-left:3px solid #667eea}
.finding-timestamp{color:#999;font-size:0.85em}.severity-badge{padding:5px 12px;border-radius:20px;font-size:0.85em;font-weight:600;text-transform:uppercase}
.severity-critical{background:#dc3545;color:white}.severity-high{background:#fd7e14;color:white}.severity-medium{background:#ffc107;color:#333}
.severity-low{background:#28a745;color:white}.footer{background:#1e3c72;color:white;padding:20px;text-align:center}
@media print{body{background:white;padding:0}}
</style></head><body><div class="container"><div class="header"><h1>🔒 Security Audit Report</h1><div class="subtitle">Professional Windows Security Assessment</div></div>
<div class="metadata"><div class="metadata-item"><strong>Computer</strong><span>$($AuditData.Metadata.ComputerName)</span></div>
<div class="metadata-item"><strong>Date</strong><span>$($AuditData.Metadata.AuditDate)</span></div>
<div class="metadata-item"><strong>Type</strong><span>$($AuditData.Metadata.AuditType)</span></div>
<div class="metadata-item"><strong>Executed By</strong><span>$($AuditData.Metadata.ExecutedBy)</span></div>
<div class="metadata-item"><strong>Admin Mode</strong><span>$($AuditData.Metadata.IsAdmin)</span></div>
<div class="metadata-item"><strong>Version</strong><span>$($AuditData.Metadata.FrameworkVersion)</span></div></div>
<div class="summary"><h2>Executive Summary</h2><div class="stats-grid">
<div class="stat-card"><div class="stat-number">$totalCount</div><div class="stat-label">Total Checks</div></div>
<div class="stat-card pass"><div class="stat-number">$passCount</div><div class="stat-label">Passed</div><div class="stat-percent">$passPercent%</div></div>
<div class="stat-card fail"><div class="stat-number">$failCount</div><div class="stat-label">Failed</div><div class="stat-percent">$failPercent%</div></div>
<div class="stat-card warn"><div class="stat-number">$warnCount</div><div class="stat-label">Warnings</div><div class="stat-percent">$warnPercent%</div></div>
<div class="stat-card risk"><div class="stat-number">$riskScore</div><div class="stat-label">Risk Score</div><div class="stat-percent">$riskLevel Risk</div></div>
</div></div><div class="findings"><h2>Detailed Findings</h2>$findingsHTML</div>
<div class="footer"><p>Security Audit Framework v$($AuditData.Metadata.FrameworkVersion) | Generated on $($AuditData.Metadata.AuditDate)</p>
<p>This report contains sensitive security information. Handle with care.</p></div></div></body></html>
"@
}
Export-ModuleMember -Function New-HTMLReport
