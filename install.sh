#!/usr/bin/env bash

# Read password from script parameter
PASSWORD=$1

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install-geodata

curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list

apt update && apt install cloudflare-warp -y
echo "Y" | warp-cli register
warp-cli set-mode proxy
warp-cli connect

cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "shadowsocks",
            "settings": {
                "method": "xchacha20-ietf-poly1305",
                "password": "$PASSWORD"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "socks",
            "settings": {
                "servers": [
                    {
                        "address": "127.0.0.1",
                        "port": 40000
                    }
                ]
            }
        },
        {
            "protocol": "freedom",
            "tag": "direct",
            "settings": {}
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "domain": ["chat.openai.com"],
                "outboundTag": "socks"
            },
            {
                "type": "field",
                "inboundTag": [
                    "shadowsocks"
                ],
                "outboundTag": "direct"
            }
        ]
    }
}
EOF

systemctl enable xray && systemctl restart xray
