# ============================================================
# zerotier-planet-from-ztncui
# 完全自包含构建：
#   - 从 ZeroTierOne 源码编译 zerotier-one（启用 UPnP/NAT-PMP 与 controller）
#   - 从 ZeroTierOne 源码编译 mkworld，生成真正的自建 planet
#   - 使用本仓库 src/ 目录中的 ztncui Web UI
# ============================================================

# -------- 阶段 1：编译 mkworld --------
FROM alpine:3.18 AS builder

RUN apk update \
    && apk add --no-cache git g++ make linux-headers ca-certificates

# 克隆 ZeroTierOne 源码
# mkworld 与 zerotier-one 主版本解耦，1.14.2 的 mkworld 可兼容 1.16.2
RUN git clone --depth 1 --branch 1.14.2 https://github.com/zerotier/ZeroTierOne.git /zt-src

WORKDIR /zt-src/attic/world
COPY mkworld_custom.cpp ./mkworld.cpp
# 使用静态编译，避免最终 Debian 镜像缺少 musl 库
RUN sed -i 's/-g -o mkworld/-static -g -o mkworld/' build.sh \
    && sh build.sh \
    && chmod +x mkworld \
    && ls -la /zt-src/attic/world/mkworld

# -------- 阶段 2：编译带 UPnP 支持的 zerotier-one --------
FROM debian:12 AS zt-builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential git libssl-dev libminiupnpc-dev libnatpmp-dev ca-certificates curl pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

RUN git clone --depth 1 --branch 1.16.2 https://github.com/zerotier/ZeroTierOne.git /zt-src

WORKDIR /zt-src
RUN make -j$(nproc) ZT_USE_MINIUPNPC=1 ZT_NONFREE=1 \
    && ls -la zerotier-one \
    && ./zerotier-one -v

# -------- 阶段 3：最终运行镜像 --------
FROM debian:12-slim

LABEL org.opencontainers.image.title="zerotier-planet-from-ztncui"
LABEL org.opencontainers.image.description="ZeroTier Planet/Moon Server with ztncui Web UI, real planet generation and tertiaryPort support"
LABEL org.opencontainers.image.version="v1.16.2.2"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       supervisor gosu nodejs npm python3 \
       libminiupnpc17 libnatpmp1 \
       ca-certificates curl jq openssl iproute2 procps net-tools \
    && rm -rf /var/lib/apt/lists/*

# 创建运行用户
RUN id -u zerotier-one >/dev/null 2>&1 || useradd -r -s /bin/false -d /var/lib/zerotier-one zerotier-one

# 复制编译好的 zerotier-one 并创建符号链接
COPY --from=zt-builder /zt-src/zerotier-one /usr/sbin/zerotier-one
RUN ln -sf /usr/sbin/zerotier-one /usr/sbin/zerotier-cli \
    && ln -sf /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool

# 复制编译好的 mkworld 工具
COPY --from=builder /zt-src/attic/world/mkworld /usr/local/bin/mkworld

# 复制本仓库的 ztncui 源码并安装依赖
COPY src /opt/key-networks/ztncui
RUN cd /opt/key-networks/ztncui \
    && npm install \
    && npm cache clean --force

# 复制启动脚本与进程管理配置
COPY start_zt1.sh /start_zt1.sh
COPY start_ztncui.sh /start_ztncui.sh
COPY start_ztplaserv.sh /start_ztplaserv.sh
COPY supervisord.conf /etc/supervisord.conf

# 创建数据目录并设置权限
RUN mkdir -p /var/lib/zerotier-one \
    /opt/key-networks/ztncui/etc \
    /opt/key-networks/ztncui/etc/tls \
    /opt/key-networks/ztncui/etc/storage \
    /opt/key-networks/ztncui/etc/myfs \
    && chown -R zerotier-one:zerotier-one /var/lib/zerotier-one /opt/key-networks/ztncui \
    && chmod +x /start_zt1.sh /start_ztncui.sh /start_ztplaserv.sh /usr/local/bin/mkworld /usr/sbin/zerotier-one

EXPOSE 9993/udp 9993/tcp 29993/udp 39993/udp 23180/tcp 23000/tcp

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisord.conf"]
