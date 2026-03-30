#!/bin/bash

# =================================================================
# Project: Linux Server Hardening Script (RHEL/Rocky 9)
# Author: Danny
# RHCSA Skills: Firewalld, SSH, SELinux, PAM/Chage, User Mgmt
# =================================================================

# 检查 Root 权限
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root. Use sudo."
   exit 1
fi

echo "--- [1/5] Starting System Hardening: User Management ---"

NEW_USER="sysadmin"
if id "$NEW_USER" &>/dev/null; then
    echo "User $NEW_USER already exists. Skipping creation."
else
    useradd -m -G wheel $NEW_USER
    echo "Set password for $NEW_USER:"
    passwd $NEW_USER
    
    # 强制设置密码激活日期为今天，防止远程登录被 PAM 拦截
    chage -d $(date +%F) -m 0 -M 99999 -I -1 -E -1 $NEW_USER
    
    # 确保家目录权限正确
    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER
    chmod 700 /home/$NEW_USER
    echo "User $NEW_USER created and account aging policy normalized."
fi

# 恢复 SELinux 上下文
echo "Restoring SELinux context for /home/$NEW_USER..."
restorecon -Rv /home/$NEW_USER

echo "--- [2/5] Configuring Firewalld ---"
systemctl enable --now firewalld &>/dev/null
firewall-cmd --permanent --add-service={http,https} &>/dev/null
firewall-cmd --permanent --add-port=2222/tcp &>/dev/null
firewall-cmd --reload &>/dev/null
echo "Firewall: Allowed HTTP, HTTPS, and Custom SSH Port 2222."

echo "--- [3/5] SSH Hardening & Protocol Enforcement ---"
SSH_CONFIG="/etc/ssh/sshd_config"
PORT=2222

cp $SSH_CONFIG "${SSH_CONFIG}.bak"

# 1. 修改端口与禁用 Root 登录
sed -i "s/^#Port 22/Port $PORT/" $SSH_CONFIG
sed -i '/PermitRootLogin/d' $SSH_CONFIG
echo "PermitRootLogin no" >> $SSH_CONFIG

# 2. 核心修复：确保认证协议参数被显式开启 (处理注释或缺失)
# 定义需要强制开启的参数
declare -a SSH_PARAMS=(
    "PasswordAuthentication yes"
    "KbdInteractiveAuthentication yes"
    "ChallengeResponseAuthentication yes"
    "UsePAM yes"
)

for param in "${SSH_PARAMS[@]}"; do
    key=$(echo $param | awk '{print $1}')
    # 先删除已存在的行（包括被注释的），再在文件末尾追加确定的值
    sed -i "/^#*$key/d" $SSH_CONFIG
    echo "$param" >> $SSH_CONFIG
done

# 3. 清理子配置干扰
if [ -d "/etc/ssh/sshd_config.d/" ]; then
    rm -f /etc/ssh/sshd_config.d/*.conf
    echo "Cleaned conflicting configs in sshd_config.d/."
fi

# 4. SELinux 端口打标与布尔值开启
if ! semanage port -l | grep -q $PORT; then
    dnf install -y policycoreutils-python-utils &>/dev/null
    semanage port -a -t ssh_port_t -p tcp $PORT
fi
setsebool -P ssh_chroot_rw_homedirs on

systemctl restart sshd
echo "SSH Service hardened and restarted on port $PORT."

echo "--- [4/5] Automation: Security Updates ---"
echo "0 2 * * * root dnf update -y" > /etc/cron.d/daily-update
chmod 644 /etc/cron.d/daily-update
echo "Cron: Scheduled daily security updates at 02:00."

echo "--- [5/5] Hardening Completed ---"
echo "VERIFICATION: ssh -p $PORT $NEW_USER@$(hostname -I | awk '{print $1}')"
