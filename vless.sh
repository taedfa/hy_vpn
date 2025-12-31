#!/bin/bash

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

# 1. 安装 Xray 核心
echo -e "${YELLOW}正在安装 Xray 官方核心...${PLAIN}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 2. 生成随机参数
UUID=$(xray uuid)
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk -F ': ' '{print $2}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk -F ': ' '{print $2}')
IP=$(curl -s4m8 ip.sb || curl -s6m8 ip.sb)

# 3. 创建配置文件
cat << EOF > /usr/local/etc/xray/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "dl.google.com:443",
                    "xver": 0,
                    "serverNames": [
                        "dl.google.com"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": [
                        "16"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF

# 4. 重启服务
systemctl restart xray
systemctl enable xray

# 5. 安装二维码生成工具（如果不存在）
if [[ -z $(type -P qrencode) ]]; then
    if [[ -f /usr/bin/apt ]]; then
        apt-get update && apt-get install -y qrencode
    elif [[ -f /usr/bin/yum ]]; then
        yum install -y epel-release && yum install -y qrencode
    fi
fi

# 6. 生成分享链接
VLESS_LINK="vless://$UUID@$IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=dl.google.com&fp=chrome&pbk=$PUBLIC_KEY&sid=16&type=tcp&headerType=none#VLESS_Reality_TUN"

# 7. 打印结果
clear
echo -e "${GREEN}=========================================="
echo -e "VLESS Reality 部署完成！"
echo -e "该协议对 TUN 模式支持极佳，请放心使用。"
echo -e "==========================================${PLAIN}"
echo ""
echo -e "${YELLOW}节点分享链接：${PLAIN}"
echo -e "${RED}$VLESS_LINK${PLAIN}"
echo ""
echo -e "${YELLOW}节点二维码：${PLAIN}"
qrencode -t ANSIUTF8 "$VLESS_LINK"
echo ""
echo -e "${GREEN}==========================================${PLAIN}"
