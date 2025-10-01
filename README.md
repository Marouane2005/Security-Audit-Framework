# Security Audit Framework v2.0

## 🔒 Overview
Professional Windows security assessment framework built with PowerShell.

## ✨ Features
- System Security Audit (Windows Defender, UAC, Firewall)
- User & Privilege Audit (Admin accounts, passwords)
- Network Security Audit (Shares, RDP)
- Beautiful HTML Reports
- Risk Scoring System
- Quick & Full Scan Modes

## 🚀 Quick Start

### Run Full Audit
```powershell
.\Start-SecurityAudit.ps1 -AuditType Full -OpenReport
```

### Run Quick Audit
```powershell
.\Start-SecurityAudit.ps1 -AuditType Quick
```

## 📋 Requirements
- Windows 10/11 or Server 2016+
- PowerShell 5.1+
- Administrator privileges (recommended)

## 📁 Structure
```
SecurityAuditFramework/
├── Start-SecurityAudit.ps1 (Main script)
├── Modules/
│   ├── Core/
│   │   ├── Utilities.psm1
│   │   └── Reporter.psm1
│   └── Audits/
│       ├── SystemSecurity.psm1
│       ├── UserAudits.psm1
│       └── NetworkSecurity.psm1
├── Reports/ (Generated HTML reports)
└── README.md
```

## 🔍 Security Checks
- Windows Defender status
- Real-time protection
- UAC configuration
- Firewall profiles
- Administrator accounts
- Guest account status
- Password policies
- Network shares
- RDP configuration

## 📊 Reports
Reports are saved to: `Reports\SecurityAudit_[ComputerName]_[Timestamp].html`

## 🛡️ Author
Security Audit Framework v2.0
