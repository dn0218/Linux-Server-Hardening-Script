
During development on RHEL 9, we identified that hardening often fails due to a breakdown in the Authentication Chain. The script now includes automated fixes for these four critical areas:

1. SELinux Enforcement
Issue: Using a non-standard port (2222) or modifying /home directories causes SSH to silently reject connections due to security label mismatches.

Fix: The script performs semanage port labeling and restorecon to ensure all files and ports meet SELinux policy requirements.

2. PAM & Account "Stale" State
Issue: Newly created users are often flagged as "uninitialized" in the shadow file, requiring a password change on first local login. This prevents immediate SSH access.

Fix: We use chage -d $(date +%F) to manually activate the account's password timestamp, enabling instant remote login.

3. Configuration Overrides (sshd_config.d)
Issue: RHEL 9 loads modular configs from /etc/ssh/sshd_config.d/ which can override your main settings.

Fix: The script purges conflicting sub-configs to ensure your security settings remain the "Single Source of Truth."

4. Authentication Protocol Enforcement
Issue: Modern RHEL versions default to Key-only auth, often ignoring Password or Challenge-Response attempts.

Fix: The script explicitly enables PasswordAuthentication, KbdInteractiveAuthentication, and UsePAM to ensure a reliable login experience for the admin user.
