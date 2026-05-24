FROM lu920115/zerotier-planet:v1.14.1.2

# 更新系统包以修复 CVE 漏洞
RUN set -x \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        curl jq openssl ca-certificates \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 验证 zerotier-one 仍然可用
RUN zerotier-one -v

LABEL org.opencontainers.image.title="zerotier-planet" \
      org.opencontainers.image.version="v1.16.1.1" \
      org.opencontainers.image.description="ZeroTier Planet Server with CVE fixes"
