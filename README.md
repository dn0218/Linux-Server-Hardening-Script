# Linux Server Hardening Script (RHEL 9)

This repository contains a professional Bash script to automate the initial hardening of RHEL/Rocky Linux 9 servers.

## 🛠 Features
- **User Management**: Automated creation of sudo users.
- **Network Security**: Strict firewalld configuration.
- **SSH Hardening**: Port remapping and Root login disabling.
- **Automation**: Cron-based security updates.

## 🔴 RHCSA Skills Applied
- Systemd service management
- Advanced file editing with 'sed'
- Firewalld & SELinux configuration
- Logical task scheduling (Cron)

## ⚠️ Troubleshooting & Lessons Learned

### 1. SELinux & SSH Port Change
**Problem:** Changing the SSH port from 22 to 2222 in `sshd_config` caused the `sshd.service` to fail on RHEL 9.
**Root Cause:** SELinux enforces strict policies on network ports. By default, only port 22 is labeled for SSH (`ssh_port_t`).
**Solution:** The script now includes a check for `semanage`. It automatically adds the new port to the SELinux policy using:
\`\`\`bash
semanage port -a -t ssh_port_t -p tcp 2222
\`\`\`
*Note: This requires the `policycoreutils-python-utils` package.*

### 2. Firewall Persistence
**Problem:** Direct changes to `iptables` or runtime `firewall-cmd` would vanish after a reboot.
**Solution:** Used the `--permanent` flag with `firewall-cmd` followed by a `--reload` to ensure rules survive system restarts, a key requirement for RHCSA compliance.
