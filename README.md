# zerotier-planet-from-ztncui

基于 [key-networks/ztncui](https://github.com/key-networks/ztncui) 修改的 **ZeroTier 自建 Planet / Moon 服务器**，并带有 Web 管理界面。

本仓库完全自包含，**无需依赖任何第三方预构建镜像**，可直接通过 `docker build` 从零构建出可运行的容器。

## 主要功能

- **ztncui Web UI**：创建/管理 ZeroTier 网络、成员、IP 分配等。
- **真正的自建 planet**：从 ZeroTierOne 源码编译 `mkworld`，生成带自签名的 planet 文件。
- **自动生成 moon**：使用 `zerotier-idtool initmoon` 生成带正确签名的 moon 文件。
- **planet + moon 文件 HTTP 下载**：容器内置简易 HTTP 下载服务。
- **UPnP/NAT-PMP 支持**：编译 zerotier-one 时启用 `ZT_USE_MINIUPNPC=1`，可使用 tertiaryPort（39993）。
- **完全自包含 Dockerfile**：从源码编译 zerotier-one、mkworld，并安装本仓库的 ztncui。

## 文件说明

| 文件 | 说明 |
|------|------|
| `Dockerfile` | 多阶段构建，从源码编译 zerotier-one、mkworld、ztncui |
| `mkworld_custom.cpp` | mkworld 源码补丁，从 `moon.json` 读取根节点配置 |
| `start_zt1.sh` | 生成 moon/planet、启动 zerotier-one |
| `start_ztncui.sh` | 启动 ztncui Web 管理界面 |
| `start_ztplaserv.sh` | 提供 planet/moon 文件 HTTP 下载 |
| `supervisord.conf` | 三进程管理配置 |
| `src/` | ztncui Web UI 源码 |
| `test_v1.16.2.2.sh` | 本地构建后快速验证脚本 |

## 前置要求

- 一台有公网 IP 的服务器，或内网设备 + 端口转发。
- Docker 20.10+（推荐开启 buildx）。
- 如需动态公网 IP，准备一个**只返回 A 记录**的 DDNS 域名，例如 `zt.example.com`。

> 不建议在 planet 文件里使用域名，planet 只支持 IP 地址。动态 IP 请使用 **moon + DDNS** 方案。

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/YOUR_USERNAME/zerotier-planet-from-ztncui.git
cd zerotier-planet-from-ztncui
```

> 将 `YOUR_USERNAME` 替换为实际的 GitHub 用户名。

### 2. 构建镜像

```bash
docker build --platform linux/amd64 -t zerotier-planet-from-ztncui:v1.16.2.2 .
```

> 构建时间约 10–30 分钟，取决于网络和机器性能。ARM64 平台可去掉 `--platform linux/amd64`。

### 3. 运行容器

#### Docker Compose（推荐）

```yaml
services:
  zerotier-planet:
    image: zerotier-planet-from-ztncui:v1.16.2.2
    container_name: zerotier-planet
    restart: unless-stopped
    network_mode: host
    environment:
      - MYADDR=zt.example.com          # 必填：公网 IP 或 DDNS 域名
      - HTTP_PORT=23000                # ztncui Web UI 端口
      - HTTP_ALL_INTERFACES=yes        # 监听所有接口（HTTP 模式）
      - ZTNCUI_PASSWD=your_password    # 仅首次生成默认密码时无效，建议启动后登录修改
    volumes:
      - ./zerotier-one:/var/lib/zerotier-one
      - ./ztncui/etc:/opt/key-networks/ztncui/etc
    cap_add:
      - NET_ADMIN
```

```bash
docker compose up -d
```

> 强烈建议使用 `network_mode: host`，避免 Docker NAT 改写端口导致 ZeroTier 连接异常。

#### Docker CLI

```bash
docker run -d \
  --name zerotier-planet \
  --network host \
  --restart unless-stopped \
  -e MYADDR=zt.example.com \
  -e HTTP_PORT=23000 \
  -e HTTP_ALL_INTERFACES=yes \
  -v $(pwd)/zerotier-one:/var/lib/zerotier-one \
  -v $(pwd)/ztncui/etc:/opt/key-networks/ztncui/etc \
  --cap-add NET_ADMIN \
  zerotier-planet-from-ztncui:v1.16.2.2
```

### 4. 访问 Web UI

```
http://服务器IP或域名:23000
```

- 默认用户名：`admin`
- 默认密码：`admin`
- 首次登录后必须修改密码（至少 10 位字符）。

### 5. 下载 moon / planet 文件

```bash
# 查看可下载文件
curl http://服务器IP或域名:23180/

# 下载 planet（固定 IP 场景）
wget http://服务器IP或域名:23180/planet

# 下载 moon（动态 IP 推荐）
wget http://服务器IP或域名:23180/xxxxxxxxxx.moon
```

## 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `MYADDR` | ✅ | 无 | 公网 IP 或 DDNS 域名。**动态公网 IP 强烈推荐用纯 IPv4 DDNS 域名** |
| `ZTNCUI_PASSWD` | ❌ | `admin` | 当前启动脚本使用 Node.js argon2 生成默认密码，启动后请通过 Web UI 修改 |
| `GENERATE_PLANET` | ❌ | `true` | 是否生成真正的 planet 文件 |
| `HTTP_PORT` | ❌ | `3000` | ztncui HTTP 端口 |
| `HTTP_ALL_INTERFACES` | ❌ | `yes` | 设置后 ztncui 监听所有接口的 HTTP_PORT，不启用 HTTPS |
| `HTTPS_PORT` | ❌ | `3443` | 未设置 `HTTP_ALL_INTERFACES` 时启用 HTTPS 端口 |
| `MYDOMAIN` | ❌ | `ztncui.docker.test` | 生成自签名证书时使用的 CN |

## 端口说明

| 端口 | 协议 | 用途 | 是否必须放行 |
|------|------|------|-------------|
| 9993/udp | UDP | ZeroTier 主通信端口 | ✅ 必须 |
| 29993/udp | UDP | secondary 端口 | 强烈建议 |
| 39993/udp | UDP | tertiary 端口 | 强烈建议 |
| 23000/tcp | TCP | ztncui Web 管理界面 | 是 |
| 23180/tcp | TCP | planet/moon 文件下载 | 是 |

> 外网端口必须等于内网端口（见下方【常见坑】第 4 条）。

## 路由器端口转发示例

以 iStoreOS / OpenWrt 为例，外网端口与内网端口保持一致：

| 规则名 | 来源 | 目标 |
|--------|------|------|
| zerotier-planet-9993 | wan:9993/udp | 192.168.x.x:9993/udp |
| zerotier-planet-29993 | wan:29993/udp | 192.168.x.x:29993/udp |
| zerotier-planet-39993 | wan:39993/udp | 192.168.x.x:39993/udp |
| ztncui-web | wan:23000/tcp | 192.168.x.x:23000/tcp |
| ztplaserv-download | wan:23180/tcp | 192.168.x.x:23180/tcp |

## IPv6 通信规则示例

| 字段 | 填写 |
|------|------|
| 名称 | `allow-zerotier-ipv6` |
| 协议 | `UDP` |
| 源区域 | `wan` + `wan6` |
| 源端口 | 留空 |
| 目标区域 | `lan` |
| 目标地址 | 留空 |
| 目标端口 | `9993 29993 39993` |
| 动作 | `接受` |

## 客户端接入

### 方案 A：安装 Moon（动态公网 IP 推荐）

1. 配置一个**只返回 A 记录**的 DDNS 域名，如 `zt.example.com`。
2. 客户端安装 moon 文件。
3. 公网 IP 变化后，DDNS 自动更新，客户端无需重新安装 moon。

```bash
# 下载 moon 文件（文件名以实际为准）
wget http://服务器IP或域名:23180/xxxxxxxxxx.moon

# 安装
mkdir -p /var/lib/zerotier-one/moons.d
cp xxxxxxxxxx.moon /var/lib/zerotier-one/moons.d/
systemctl restart zerotier-one

# 验证
zerotier-cli listmoons
```

### 方案 B：替换 Planet（仅固定公网 IP）

```bash
# 下载 planet 文件
wget http://服务器IP或域名:23180/planet

# 替换
systemctl stop zerotier-one
cp planet /var/lib/zerotier-one/planet
systemctl start zerotier-one
```

> 公网 IP 变化后，必须重新生成 planet 文件并重新分发到所有客户端。

### 能不能把官方 planet 节点也写进自建 planet？

**不能。** planet 文件需要签名验证，你没有官方私钥，混进去会导致客户端验证失败。

## Web UI 使用简介

1. 登录后创建 Network。
2. 点击 **easy setup** 自动分配网段，或手动配置。
3. 客户端使用 `zerotier-cli join <Network ID>` 加入。
4. 在 Web UI 中授权成员上线。

更多 ztncui 原始文档见 [key-networks/ztncui](https://github.com/key-networks/ztncui)。

## 动态 IP 维护 checklist

- [ ] DDNS 域名只配置 A 记录（IPv4）
- [ ] 路由器放行上述 UDP 端口
- [ ] 路由器端口转发到运行容器的设备（外网端口 = 内网端口）
- [ ] 客户端安装 moon 文件而非替换 planet
- [ ] 定期备份 `./zerotier-one` 卷（包含 identity 和签名密钥）

## 常见坑与解决方案

### 1. tertiaryPort（39993）不监听

**现象**：`local.conf` 里配置了 `tertiaryPort: 39993`，但 `netstat` 看不到 39993。

**原因**：
- zerotier-one 二进制没有编译 UPnP 支持（`ZT_USE_MINIUPNPC`）
- 或 `portMappingEnabled` 为 false

**解决**：

```json
{
  "settings": {
    "primaryPort": 9993,
    "secondaryPort": 29993,
    "tertiaryPort": 39993,
    "allowSecondaryPortRelay": true,
    "portMappingEnabled": true
  }
}
```

并确保镜像编译时加了 `ZT_USE_MINIUPNPC=1`（本 Dockerfile 已默认启用）。

### 2. ztncui Networks 页面 404

**现象**：ztncui 能登录，但 Networks 页面报 `HTTPError: Response code 404`。

**原因**：zerotier-one 没有编译 nonfree controller 功能（`ZT_NONFREE=1`）。

**解决**：本 Dockerfile 已默认启用 `ZT_NONFREE=1`。

### 3. 客户端更新 moon 文件后 OFFLINE

**现象**：下载新的 moon 文件放到客户端后，设备显示 OFFLINE。

**原因**：旧的 moon 生成方式 `updatesMustBeSignedBy` 全为 0，部分客户端拒绝接受。

**解决**：本仓库 `start_zt1.sh` 使用 `zerotier-idtool initmoon identity.public` 生成带 `signingKey` 的模板，再修改 `stableEndpoints`，最后 `genmoon`。

### 4. 路由器端口转发不能改端口

**现象**：把外网 39993 转发到内网 29993，ZeroTier 客户端连不上。

**原因**：ZeroTier 对源端口一致性有要求，NAT 改写目标端口后，回复包的源端口不一致，客户端会拒绝。

**解决**：外网端口必须等于内网端口：

| 外网端口 | 内网端口 |
|---------|---------|
| 9993 | 9993 |
| 29993 | 29993 |
| 39993 | 39993 |

### 5. IPv6 通信规则源端口不能填

**现象**：配置了 IPv6 通信规则，但外网 IPv6 测试还是 filtered。

**原因**：源端口填了 `9993` 等具体端口。ZeroTier 客户端源端口是随机的临时端口。

**解决**：
- 源端口留空
- 目标端口填 `9993 29993 39993`
- 协议选 UDP
- 源区域 `wan` + `wan6`，目标区域 `lan`

### 6. 移动宽带/大内网设备不上线

**现象**：移动宽带路由器或手机 4G/5G 下的 ZeroTier 客户端不上线。

**原因**：移动宽带 NAT 严格，无法直接打洞。

**解决**：
- 在这些设备上安装 moon 文件
- 确保网络中有公网 IP 节点在线（如 VPS）作为 relay
- 放行 relay 节点的 9993/udp 和 secondaryPort

## 手机客户端说明

- **Android**：官方 ZeroTier App 不支持 moon/planet 自定义，建议使用第三方修改版。
- **iOS**：官方 App 同样受限，一般需要 TestFlight 版本或越狱。
- **替代方案**：手机用官方 App 加入 Network ID，通过固定在线节点（如 VPS）中转访问。

## 构建参数

```bash
docker build --platform linux/amd64 -t zerotier-planet-from-ztncui:v1.16.2.2 .
```

- `ZT_USE_MINIUPNPC=1`：启用 UPnP/NAT-PMP 支持（Dockerfile 中已固定开启）
- `ZT_NONFREE=1`：启用 embedded controller（Dockerfile 中已固定开启）

## 本地测试

构建完成后，可运行仓库中的测试脚本做快速验证：

```bash
./test_v1.16.2.2.sh
```

测试内容：
- 检查 planet / moon 文件是否生成
- 检查 zerotier-one 是否正常运行
- 检查 ztncui Web UI 是否可访问
- 检查 planet 下载服务是否正常
- 检查 planet 文件是否不含官方 planet ID

## 数据持久化

必须使用卷挂载保存数据，否则容器删除后所有配置丢失：

| 挂载路径 | 说明 | 必须 |
|---------|------|------|
| `/var/lib/zerotier-one` | ZeroTier identity、planet、controller 网络数据 | ✅ |
| `/opt/key-networks/ztncui/etc` | ztncui 密码、TLS 证书 | ✅ |

## 版本历史

### v1.16.2.2
- 合并 zerotier-planet 与 zerotier-planet-from-ztncui 两个仓库
- Dockerfile 完全自包含，从源码编译 zerotier-one、mkworld、ztncui
- 支持真正的 planet 和 moon 生成
- 支持 tertiaryPort（39993）
- 修复 moon 文件签名问题

## License

本项目继承自 [key-networks/ztncui](https://github.com/key-networks/ztncui)，遵循 GPLv3 许可证。详见 [LICENSE](./LICENSE)。
