#!/usr/bin/env bash

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install-geodata

curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

sudo apt update 
sudo apt install cloudflare-warp
warp-cli register
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
                "password": "password"
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
                "inboundTag": [
                    "shadowsocks"
                ],
                "outboundTag": "socks"
            }
        ]
    }
}
EOF

sudo systemctl enable xray && sudo systemctl restart xray
