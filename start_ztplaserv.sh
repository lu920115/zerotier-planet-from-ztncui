#!/bin/bash
set -e

echo "Waiting for planet file to be generated..."
while [ ! -f /var/lib/zerotier-one/planet ]; do
    echo "Planet file is not found... Wait for ZT1 to start..."
    sleep 2
done

# 等待 ztone 完成 moon/planet 生成（v1.16.2.2 中 ztone 会重新生成 planet）
while [ ! -f /var/lib/zerotier-one/.planet_ready ]; do
    echo "Waiting for planet generation to complete..."
    sleep 2
done

echo "Planet generation completed. Copying to myfs directory..."
mkdir -p /opt/key-networks/ztncui/etc/myfs

# 复制 planet 文件
cp -f /var/lib/zerotier-one/planet /opt/key-networks/ztncui/etc/myfs/planet

# 复制 moon 文件（如果存在）
if ls /var/lib/zerotier-one/*.moon 1> /dev/null 2>&1; then
    cp -f /var/lib/zerotier-one/*.moon /opt/key-networks/ztncui/etc/myfs/
    echo "Moon files copied."
fi

ls -la /opt/key-networks/ztncui/etc/myfs/

echo "Starting planet/moon file HTTP server on port 23180..."
cd /opt/key-networks/ztncui/etc/myfs
exec python3 -m http.server 23180
