#!/bin/bash

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 请以 root 用户运行此脚本${PLAIN}" && exit 1

# 菜单函数
menu() {
    clear
    echo -e "${GREEN}==========================================${PLAIN}"
    echo -e "${GREEN}      VLESS Reality 一键管理脚本          ${PLAIN}"
    echo -e "${GREEN}==========================================${PLAIN}"
    echo -e " ${GREEN}1.${PLAIN} 安装 VLESS Reality (支持 TUN 模式)"
    echo -e " ${RED}2.${PLAIN} 卸载 VLESS Reality"
    echo -e " ${YELLOW}0.${PLAIN} 退出"
    echo -e "${GREEN}==========================================${PLAIN}"
    read -rp "请输入选项 [0-2]: " menuInput

    case $menuInput in
        1) install_vless ;;
        2) uninstall_vless ;;
        0) exit 0 ;;
        *) echo -e "${RED}请输入正确的选项!${PLAIN}" && sleep 2 && menu ;;
    esac
}

# 安装函数
install_vless() {
    echo -e "${YELLOW}正在安装 Xray 核心...${PLAIN}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    # 生成随机参数
    UUID=$(/usr/local/bin/xray uuid)
    /usr/local/bin/xray x25519 > /tmp/xray_keys.txt
    PRIVATE_KEY=$(grep "Private key:" /tmp/xray_keys.txt | awk '{print $3}')
    PUBLIC_KEY=$(grep "Public key:" /tmp/xray_keys.txt | awk '{print $3}')
    rm /tmp/xray_keys.txt

    # 获取公网 IP
    IP=$(curl -s4m8 ip.sb || curl -s6m8 ip.sb)

    # 写入配置
    mkdir -p /usr/local/etc/xray
    cat << EOF > /usr/local/etc/xray/config.json
{
    "log": { "loglevel": "warning" },
    "inbounds": [{
        "port": 443,
        "protocol": "vless",
        "settings": {
            "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "tcp",
            "security": "reality",
            "realitySettings": {
                "show": false,
                "dest": "www.microsoft.com:443",
                "xver": 0,
                "serverNames": ["www.microsoft.com"],
                "privateKey": "$PRIVATE_KEY",
                "shortIds": ["16"]
            }
        }
    }],
    "outbounds": [{ "protocol": "freedom" }]
}
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl restart xray
    systemctl enable xray

    # 安装二维码工具
    if ! command -v qrencode &> /dev/null; then
        apt-get update && apt-get install -y qrencode || yum install -y qrencode
    fi

    # 生成链接
    VLESS_LINK="vless://$UUID@$IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=16&type=tcp&headerType=none#VLESS_Reality_TUN"

    clear
    echo -e "${GREEN}安装成功！以下是您的配置信息：${PLAIN}"
    echo -e "${YELLOW}------------------------------------------${PLAIN}"
    echo -e "${BLUE}地址 (Address):${PLAIN} $IP"
    echo -e "${BLUE}端口 (Port):${PLAIN} 443"
    echo -e "${BLUE}用户 ID (UUID):${PLAIN} $UUID"
    echo -e "${BLUE}流控 (Flow):${PLAIN} xtls-rprx-vision"
    echo -e "${BLUE}公钥 (Public Key):${PLAIN} $PUBLIC_KEY"
    echo -e "${BLUE}伪装域名 (SNI):${PLAIN} www.microsoft.com"
    echo -e "${YELLOW}------------------------------------------${PLAIN}"
    echo -e "${RED}分享链接:${PLAIN}\n$VLESS_LINK"
    echo ""
    echo -e "${YELLOW}二维码:${PLAIN}"
    qrencode -t ANSIUTF8 "$VLESS_LINK"
    echo -e "${YELLOW}------------------------------------------${PLAIN}"
    echo -e "${GREEN}提示: 若链接无法自动导入公钥，请手动复制上方 Public Key 填入。${PLAIN}"
}

# 卸载函数
uninstall_vless() {
    echo -e "${RED}正在停止并彻底删除 VLESS 相关服务和文件...${PLAIN}"
    systemctl stop xray
    systemctl disable xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
    rm -rf /usr/local/etc/xray
    rm -rf /var/log/xray
    echo -e "${GREEN}卸载完成！${PLAIN}"
    sleep 2
    menu
}

# 运行菜单
menu
