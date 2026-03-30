#!/bin/bash

# =================================================================
# Project: Linux Server Hardening Script (RHEL/Rocky 9)
# Author: [Your Name] - Network & SysAdmin
# RHCSA Skills Demo: Firewalld, SSH, User Mgmt, Cron
# =================================================================

# check root priviledge
if [[ $EUID -ne 0 ]]; then
   echo "此脚本必须以 root 权限运行，请使用 sudo。"
   exit 1
fi

echo "--- 开始服务器安全加固 ---"

# 1. user management, new sudoer
NEW_USER="sysadmin"
if id "$NEW_USER" &>/dev/null; then
    echo "USER $NEW_USER existed，skip creation。"
else
    useradd -m -G wheel $NEW_USER
    echo "Create $NEW_USER 's new password："
    passwd $NEW_USER
    echo "User $NEW_USER Created successfully and added in wheel group。"
fi

# 2. 网络安全：配置 Firewalld
# Only allow necessary daemon（SSH, HTTP, HTTPS）
echo "Config Firewall..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
echo "Firewall rules set：Only allow SSH/HTTP/HTTPS。"

# 3. SSH Hardening
echo "加固 SSH 服务并更新 SELinux 策略..."
SSH_CONFIG="/etc/ssh/sshd_config"
PORT=2222

# 修改配置文件
sed -i "s/#Port 22/Port $PORT/" $SSH_CONFIG
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' $SSH_CONFIG

# --- RHCSA 核心补丁：处理 SELinux ---
if command -v semanage &> /dev/null; then
    semanage port -a -t ssh_port_t -p tcp $PORT
else
    # 如果没装工具，先安装再执行
    dnf install -y policycoreutils-python-utils
    semanage port -a -t ssh_port_t -p tcp $PORT
fi

# 防火墙开启新端口
firewall-cmd --permanent --add-port=$PORT/tcp
firewall-cmd --reload
systemctl restart sshd
echo "SSH 加固完成，SELinux 策略已更新。"

# 4. Automation：Cron job auto update
# 场景：确保系统始终安装安全补丁
echo "Daily auto update & upgrade..."
echo "0 2 * * * root dnf update -y" > /etc/cron.d/daily-update
echo "Cron Task created：02:00 Auto upgrade daily。"

echo "--- OS hardening Completed！Please noted the new SSH Port: 2222 ---"
