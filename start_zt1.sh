#!/bin/bash
set -e

cd /tmp

ZEROTIER_PATH="/var/lib/zerotier-one"

# ============================================================
# 1. 基础目录和 identity 初始化
# ============================================================
if [ ! -f "${ZEROTIER_PATH}/identity.secret" ]; then
    echo "Zerotier-One Configuration is **NOT** initialized."
    mkdir -p "${ZEROTIER_PATH}"
    rm -rf "${ZEROTIER_PATH}"/*

    ln -sf /usr/sbin/zerotier-one "${ZEROTIER_PATH}/zerotier-cli"
    ln -sf /usr/sbin/zerotier-one "${ZEROTIER_PATH}/zerotier-idtool"
    ln -sf /usr/sbin/zerotier-one "${ZEROTIER_PATH}/zerotier-one"

    # 创建 zerotier-one 用户（如果不存在）
    id -u zerotier-one >/dev/null 2>&1 || useradd -r -s /bin/false zerotier-one
    chown zerotier-one:zerotier-one "${ZEROTIER_PATH}"

    # 生成 identity
    cd "${ZEROTIER_PATH}"
    ./zerotier-idtool generate identity.secret identity.public
    echo "Identity generated: $(cat identity.public | cut -d: -f1)"
else
    echo "Zerotier-One Configuration is initialized."
fi

cd "${ZEROTIER_PATH}"

# ============================================================
# 2. 读取环境变量
# ============================================================
MYADDR=${MYADDR:-}
GENERATE_PLANET=${GENERATE_PLANET:-true}

if [ -z "$MYADDR" ]; then
    echo "ERROR: MYADDR environment variable is required."
    echo ""
    echo "Recommended: use an IPv4-only DDNS domain for dynamic public IP:"
    echo "  MYADDR=zt.example.com"
    echo ""
    echo "Note: do NOT use a domain with AAAA (IPv6) record if your clients only have IPv4."
    exit 1
fi

echo "============================================================"
echo "ZeroTier Planet/Moon Server v1.16.2.2"
echo "============================================================"
echo "MYADDR: ${MYADDR}"
echo "GENERATE_PLANET: ${GENERATE_PLANET}"
echo ""
echo "Recommendation for dynamic public IP:"
echo "  1. Use MOON file + DDNS domain (best for dynamic IP)"
echo "  2. Planet file replacement is optional and only for fixed IP"
echo ""
echo "Resolving IPv4 address for MYADDR..."
IPV4_ADDR=$(python3 -c "import socket; print([x[4][0] for x in socket.getaddrinfo('${MYADDR}', None, socket.AF_INET)][0])" 2>/dev/null)
if [ -z "$IPV4_ADDR" ]; then
    echo "ERROR: Failed to resolve IPv4 address for ${MYADDR}."
    echo "If your domain has AAAA (IPv6) record but no A record, moon/planet generation will fail."
    echo "Please use an IPv4-only DDNS domain like zt.example.com."
    exit 1
fi
echo "Resolved IPv4 address: ${IPV4_ADDR}"
echo "============================================================"

# ============================================================
# 3. 生成 moon.json
# ============================================================
# 使用 initmoon 生成带 signingKey 的模板，再填入 stableEndpoints。
# 直接手写 moon.json 会导致签名中的 updatesMustBeSignedBy 全 0，
# 部分客户端（如老版本 zerotier-one）可能拒绝该 moon 文件。
./zerotier-idtool initmoon identity.public > moon.json
python3 -c "
import json
with open('moon.json', 'r') as f:
    d = json.load(f)
d['roots'][0]['stableEndpoints'] = [
    '${IPV4_ADDR}/9993',
    '${IPV4_ADDR}/29993',
    '${IPV4_ADDR}/39993'
]
with open('moon.json', 'w') as f:
    json.dump(d, f, indent=2)
"

NODE_ID=$(cat identity.public | cut -d: -f1)

echo "Generated moon.json with stableEndpoints:"
grep -A5 stableEndpoints moon.json

# ============================================================
# 4. 生成 .moon 文件
# ============================================================
./zerotier-idtool genmoon moon.json
mkdir -p moons.d
cp -f ./*.moon ./moons.d/
MOON_FILE=$(ls ./*.moon 2>/dev/null | head -1)
echo "Generated moon file: ${MOON_FILE}"
echo ""
echo ">>> To use MOON (recommended for dynamic IP):"
echo "    wget https://example.com:23180/$(basename ${MOON_FILE})"
echo "    mkdir -p /var/lib/zerotier-one/moons.d"
echo "    cp $(basename ${MOON_FILE}) /var/lib/zerotier-one/moons.d/"
echo "    systemctl restart zerotier-one"
echo ""

# ============================================================
# 5. 生成真正的 planet 文件（可选）
# ============================================================
if [ "$GENERATE_PLANET" = "true" ]; then
    echo "Generating planet file with mkworld..."
    /usr/local/bin/mkworld
    if [ $? -ne 0 ]; then
        echo "ERROR: mkworld failed!"
        exit 1
    fi
    mv -f world.bin planet
    echo "Planet file generated: $(ls -la planet)"
    echo ""
    echo ">>> To use PLANET replacement (only for fixed IP or special devices):"
    echo "    wget https://example.com:23180/planet"
    echo "    cp planet /var/lib/zerotier-one/planet"
    echo "    systemctl restart zerotier-one"
    echo "    WARNING: if your public IP changes, you must redistribute this file."
    echo ""
else
    echo "GENERATE_PLANET is not true, using default planet file."
fi

# 通知 ztplaserv 可以复制文件了
touch "${ZEROTIER_PATH}/.planet_ready"

# ============================================================
# 6. 启动 zerotier-one
# ============================================================
echo "Starting zerotier-one..."
exec /usr/sbin/zerotier-one
