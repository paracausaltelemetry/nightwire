# Engagement Checklist

Tick items off per host. Copy the host block for each new system in scope.

## Before you start

- [ ] Scope, rules of engagement, and testing window confirmed in writing
- [ ] VPN connected and target pinned (`nightwire vpn up`, `nightwire target`)
- [ ] VM snapshot taken (`nightwire snapshot-note pre-engagement`)
- [ ] `notes.md` and `creds.md` started

## Host: <IP / hostname>

### Discovery

- [ ] Full TCP port scan saved to `scans/`
- [ ] Service/version scan on open ports
- [ ] Top UDP ports checked
- [ ] OS and domain membership noted

### Per-service footprinting

- [ ] FTP / TFTP
- [ ] SSH
- [ ] SMTP / IMAP / POP3
- [ ] DNS (zone info, subdomains, vhosts)
- [ ] SMB / RPC / NFS
- [ ] SNMP / IPMI
- [ ] LDAP / Kerberos
- [ ] Databases (MySQL, MSSQL, Oracle TNS)
- [ ] Remote management (RDP, WinRM, WMI)
- [ ] Web (tech stack, vhosts, content discovery, known CMS/apps)

### Findings and access

- [ ] Every finding has evidence (command, output, screenshot) in `screenshots/`
- [ ] Every credential logged in `creds.md` and re-tested across in-scope hosts
- [ ] Access level and path to it written up in `notes.md`
- [ ] Network position recorded (new subnets reachable from this host)

## Wrap-up

- [ ] Changes made to systems listed for cleanup (files, accounts, services)
- [ ] Attack path diagram / narrative drafted
- [ ] Findings moved into `report-outline.md` with severity and remediation
