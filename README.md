<img width="685" height="100" alt="image" src="https://github.com/user-attachments/assets/f8ac6a91-5204-432f-ae49-5b2fe60d3d33" /># Linux Server Hardening Script (RHEL 9)

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

### 🚀 How to Run
\`\`\`bash
# Download the script
curl -O https://raw.githubusercontent.com/dn0218/Linux-Server-Hardening-Script/main/hardening.sh

# Grant execution rights
chmod +x hardening.sh

# Execute as root
sudo ./hardening.sh
\`\`\`

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

---

## 🛠️ Detailed Implementation Guide (RHCSA Compliance)

This section provides a technical breakdown of each hardening step, why it's required for a secure production environment, and how to verify its effectiveness.

### 1. User & Group Management

#### **Why?**
The `root` account is the ultimate target for attackers. Disabling root login is essential, but you must first create a **non-privileged user** with elevated permissions (`sudo`) for administrative tasks. This creates an audit trail and limits the blast radius of a compromised account.

#### **RHCSA Skill & Verification**
We utilize `useradd` with the `-G wheel` flag. In RHEL-based systems, the `wheel` group is pre-configured to grant sudo access via PAM.

**Screenshot 1: Verifying user 'sysadmin' and its sudoer group.**
![User Check]<img width="685" height="100" alt="image" src="https://github.com/user-attachments/assets/5c87a156-7b4f-4d9e-9aa3-9de1b8b5033e" />

*You can see user `sysadmin` (UID 1002) is added to group `wheel` (GID 10).*

---

### 2. Network Security: Firewalld

#### **Why?**
"Default Deny" is the golden rule of cybersecurity. A fresh server often has open ports or unnecessary services. We enforce a strict policy to **only allow** specific business services (`SSH`, `HTTP`, `HTTPS`) and block everything else to minimize the attack surface.

#### **RHCSA Skill & Verification**
We use `firewall-cmd --permanent` to ensure rules survive reboots, followed by a `--reload` to activate them without dropping current connections.

**Screenshot 2: Inspecting the active firewall zones and services.**
![Firewall Check]<img width="662" height="291" alt="image" src="https://github.com/user-attachments/assets/bf0da2e4-3554-4eac-b9ee-ae5876b47222" />

*Output confirms only `ssh`, `http`, `https` services and port `2222/tcp` are public.*

---

### 3. SSH Hardening (The RHEL 9 SELinux Challenge)

#### **Why?**
- **Custom Port (22 -> 2222):** Obfuscation. It stops 99% of automated brute-force bots targeting the default port.
- **`PermitRootLogin no`:** Forces administrators to use their own accounts, making privilege escalation (`sudo`) a conscious, auditable act.

#### **RHCSA Skill & Verification**
This is the most critical step on RHEL 9. Modifying `/etc/ssh/sshd_config` alone will cause the service to fail because SELinux, by default, blocks SSH from running on non-standard ports.

**Screenshot 3: Proof of successful SSHD service on Port 2222, and its SELinux labeling.**
![SSH & SELinux Check]<img width="678" height="313" alt="image" src="https://github.com/user-attachments/assets/d8fb66e2-5169-4bab-8620-8f3018d2efe0" />

*Left: `systemctl status sshd` shows 'active (running)' on custom port. Right: `semanage port -l` confirms port `2222` is registered as a legal `ssh_port_t`.*

---

### 4. Automation: DNF Security Patches

#### **Why?**
Outdated software is the #1 vector for successful exploits. While manual updates are great, automation ensures that even if you are on vacation, your server continues to receive daily security patches (`dnf update -y`).

#### **RHCSA Skill & Verification**
We leverage `cron.d` for robust, standard scheduling. In RHEL, this is the compliant way to schedule system-level automation.

**Screenshot 4: Verifying the created Cron job for automated daily updates.**
![Cron Check]<img width="567" height="37" alt="image" src="https://github.com/user-attachments/assets/341a9dab-0d8d-4e2f-a85e-c6633630636a" />

*`0 2 * * * root dnf update -y` means: Every day at 02:00, run the complete dnf update.*

---

## 🚀 Final Verification

After running the script, we verify the end-to-end security by attempting an external connection using the newly configured user and port.

**Screenshot 5: Successful external login from a management machine.**
![External Login]<img width="757" height="502" alt="image" src="https://github.com/user-attachments/assets/9eb562e6-2da2-4194-97bc-e963aee200cc" />

*The prompt `[sysadmin@rhel ~]$` confirms we successfully bypassed root, used the hardened port, and have an operational server.*
