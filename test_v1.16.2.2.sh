#!/bin/bash
set -e

IMAGE_NAME="zerotier-planet-from-ztncui:v1.16.2.2"
CONTAINER_NAME="ztplanet_src_test"

echo "Testing ${IMAGE_NAME}..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d --name "${CONTAINER_NAME}" \
  --platform linux/amd64 \
  -e MYADDR=127.0.0.1 \
  -e ZTNCUI_PASSWD=admin123 \
  -e HTTP_PORT=23000 \
  -e HTTP_ALL_INTERFACES=yes \
  -p 29994:9993 \
  -p 29994:9993/udp \
  -p 23000:23000 \
  -p 23180:23180 \
  "${IMAGE_NAME}" >/dev/null 2>&1

sleep 15

echo "=== 1. 生成文件 ==="
docker exec "${CONTAINER_NAME}" ls -la /var/lib/zerotier-one/planet /var/lib/zerotier-one/moons.d/ /opt/key-networks/ztncui/etc/myfs/ 2>&1

echo ""
echo "=== 2. planet 大小 ==="
docker exec "${CONTAINER_NAME}" sh -c 'wc -c /var/lib/zerotier-one/planet /opt/key-networks/ztncui/etc/myfs/planet'

echo ""
echo "=== 3. zerotier-one 状态 ==="
docker exec "${CONTAINER_NAME}" sh -c 'cd /var/lib/zerotier-one && ./zerotier-cli -T$(cat authtoken.secret) info' 2>&1

echo ""
echo "=== 4. ztncui web (port 23000) ==="
curl -sk http://127.0.0.1:23000/ | grep -o '<title>[^<]*</title>' || echo "ztncui web check failed"

echo ""
echo "=== 5. 文件下载 ==="
curl -sI http://127.0.0.1:23180/planet | head -3

echo ""
echo "=== 6. 不含官方 planet ID ==="
for id in cafe80ed74 778cde7190 cafefd6717 cafe04eba9; do
  if docker exec "${CONTAINER_NAME}" sh -c "grep -q \"$id\" /var/lib/zerotier-one/planet 2>/dev/null" 2>/dev/null; then
    echo "WARNING: Found official planet ID $id"
  else
    echo "OK: No official planet ID $id"
  fi
done

docker stop "${CONTAINER_NAME}" >/dev/null 2>&1
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1

echo ""
echo "Test completed."
