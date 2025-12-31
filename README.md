# 一键在vps上配置hy协议
## 首先安装工具
```bash
apt update -y && apt install -y unzip && apt install -y git
```
## 再拉取脚本
```bash
git clone https://github.com/taedfa/hy_vpn.git && unzip hy_vpn.zip && chmod +x hy_vpn.sh
```
## 运行脚本
```bash
cd hy_vpn
```
## 固定本地端口
```bash
bash hysteria2.sh
```
## 随机本地端口
```bash
bash hysteria.sh
```


