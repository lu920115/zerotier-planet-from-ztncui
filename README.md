# ztncui - ZeroTier network controller user interface

ztncui is a web user interface for a standalone [ZeroTier](https://zerotier.com) network controller.

Screenshots can be seen at [key-networks.com/ztncui](https://key-networks.com/ztncui).

# ztncui - ZeroTier network controller UI (排版优化版)

这是 [key-networks/ztncui](https://github.com/key-networks/ztncui) 的修改版，**修复了 Web 管理界面 `Detail for network` 页面的 JSON 排版问题**。

## 改进内容

- 短数组/对象（如 `[null]`、`[]`、`{}`）单行显示
- 多元素数组每个 Object 紧凑一行显示
- Object 多行 1 格缩进，开头结尾括号合并
- 整体排版更紧凑，减少碎片化

## Docker 镜像

### 完整功能版（推荐）
包含 ztncui Web 管理界面、入口脚本和完整依赖，适合大多数用户。

```bash
# Docker Hub
docker pull lu920115/zerotier-planet:v1.16.1.1

# GitHub Container Registry (GHCR)
docker pull ghcr.io/lu920115/zerotier-planet:v1.16.1.1
```

### 源码编译版（仅 ZeroTier One）
从源码编译的纯净 ZeroTier One，体积仅 38MB，适合高级用户或嵌入式环境。不含 Web UI 和入口脚本。

```bash
# Docker Hub
docker pull lu920115/zerotier-planet:v1.16.1.1-full

# GitHub Container Registry (GHCR)
docker pull ghcr.io/lu920115/zerotier-planet:v1.16.1.1-full
```

### 源码编译版（含 Web UI）
从源码编译，包含 ztncui Web 管理界面、入口脚本和自动配置，体积 108MB。推荐用于生产环境。

```bash
# Docker Hub
docker pull lu920115/zerotier-planet:v1.16.1.1-full-web

# GitHub Container Registry (GHCR)
docker pull ghcr.io/lu920115/zerotier-planet:v1.16.1.1-full-web
```

**各版本区别：**

| 功能 | 完整版 `v1.16.1.1` | 编译版 `v1.16.1.1-full` | 编译版+Web `v1.16.1.1-full-web` |
|------|-------------------|------------------------|--------------------------------|
| 镜像大小 | ~790MB | ~38MB | ~108MB |
| 构建方式 | 层叠升级 | 源码编译 | 源码编译 |
| ztncui Web UI | ✅ 有 | ❌ 无 | ✅ 有 |
| 入口脚本 | ✅ 有 | ❌ 无 | ✅ 有 |
| planet 自动配置 | ✅ 支持 | ❌ 需手动 | ✅ 支持 |
| 适用场景 | 生产环境 | 高级用户、嵌入式 | **推荐生产环境** |

**编译版 (`v1.16.1.1-full`) 说明：**
- 从 ZeroTier One 1.16.1 源码编译
- 仅包含 zerotier-one 二进制，无 Web UI
- 需手动配置 planet 和 moon 服务器
- 所有操作通过 `zerotier-cli` 命令行完成

**编译版+Web (`v1.16.1.1-full-web`) 说明：**
- 从 ZeroTier One 1.16.1 源码编译
- 包含 ztncui Web 管理界面（排版优化版）
- 包含 supervisord 进程管理和自动初始化脚本
- 体积小巧，功能完整，**推荐使用**

### 启动示例

```bash
docker run -d \
  --name zerotier-planet \
  -p 9993:9993/tcp \
  -p 9993:9993/udp \
  -p 3180:3180/tcp \
  -p 3443:3443/tcp \
  -e HTTP_ALL_INTERFACES=yes \
  -e HTTP_PORT=3180 \
  -v /path/to/zerotier-one:/var/lib/zerotier-one \
  -v /path/to/ztncui/etc:/opt/key-networks/ztncui/etc \
  lu920115/zerotier-planet:v1.16.1.1-full-web
```

**⚠️ 重要：数据持久化**

必须使用 `-v` 挂载卷保存数据，否则容器删除后所有配置丢失：

| 挂载路径 | 说明 | 必须 |
|---------|------|------|
| `/var/lib/zerotier-one` | ZeroTier 身份、planet、controller 网络数据 | ✅ |
| `/opt/key-networks/ztncui/etc` | ztncui 密码、TLS 证书 | ✅ |

### 升级注意事项

**从 v1.14.1.2 升级到 v1.16.1.1-full-web：**

1. **数据兼容**：controller 网络配置格式兼容，挂载相同卷即可保留所有网络
2. **密码处理**：
   - 如果挂载了旧的 `/opt/key-networks/ztncui/etc`，旧密码仍然有效
   - **全新启动**（无挂载）时，默认用户名密码为 `admin` / `admin`
   - 首次登录后**强制修改密码**（密码长度至少 10 位）
3. **升级步骤**：
   ```bash
   # 1. 停止旧容器
   docker stop zerotier-planet
   docker rm zerotier-planet
   
   # 2. 用新镜像启动，挂载相同的数据卷
   docker run -d \
     --name zerotier-planet \
     -p 9993:9993/tcp \
     -p 9993:9993/udp \
     -p 3180:3180/tcp \
     -p 3443:3443/tcp \
     -e HTTP_ALL_INTERFACES=yes \
     -e HTTP_PORT=3180 \
     -v /path/to/old/zerotier-one:/var/lib/zerotier-one \
     -v /path/to/old/ztncui/etc:/opt/key-networks/ztncui/etc \
     lu920115/zerotier-planet:v1.16.1.1-full-web
   ```

### 默认密码

- **用户名**：`admin`
- **密码**：`admin`
- 首次登录后**必须修改密码**（至少 10 位字符）
- 修改密码前无法进入管理界面

## 版本更新记录

### v1.16.1.1-full-web (2025-05-26)
- **新增编译版+Web 镜像**：从源码编译 ZeroTier One 1.16.1，包含完整 Web UI
- **启用 embedded controller**：编译时添加 `ZT_NONFREE=1` 标志，支持网络控制器功能
- **默认密码优化**：首次启动默认密码固定为 `admin`，登录后强制修改
- **数据持久化支持**：支持挂载卷保留 zerotier-one 和 ztncui 配置

### v1.16.1.1 (2025-05-24)
- **ZeroTier One 升级**: 从 v1.14.1.2 自动升级至 v1.16.1（通过官方 apt 源）
- **CVE 漏洞修复**: 通过 `apt-get upgrade` 更新系统包，修复 82 个 CVE 漏洞
  - 修复前: 205 个漏洞 (3 Critical, 52 High, 59 Medium)
  - 修复后: 123 个漏洞 (3 Critical, 22 High, 28 Medium)
- **剩余漏洞说明**: 剩余 3 个 Critical CVE 来自 ZeroTier One 内置的 Go 依赖（zeroidc 组件），需等待 ZeroTier 官方更新

### v1.14.1.2
- 基础版本（原始构建）

## mixins.pug 修改记录（排版优化）

**问题**：routes 中 via 字段被挤到下一行，阅读不连贯  
**解决**：在 `json_value` mixin 中增加字段数判断

**修改位置**：`src/views/mixins.pug`

**关键逻辑**：
- 单元素数组（如 routes）且字段数 ≤ 2：压缩成一行
- 字段数 > 2（如 rules、v4AssignMode）：保持多行排版

**代码变动**：
在 `value.length === 1` 分支中，增加：
```javascript
if (Object.keys(item).length <= 2) {
  inner = inner.replace(/,\n\s*/g, ', ');
}

Follow us on [![alt @key_networks on Twitter](https://i.imgur.com/wWzX9uB.png)](https://twitter.com/key_networks)

## Packages
Instructions for installing on Linux from RPM or DEB packges are available at [key-networks.com/ztncui](https://key-networks.com/ztncui).

## Docker Container Image
See [https://github.com/key-networks/ztncui-aio](https://github.com/key-networks/ztncui-aio)

## Getting Started

### Note
Relative directory references below are relative to the cloned ztncui directory.

### Prerequisites
* ztncui is a [node.js](https://nodejs.org) [Express](https://expressjs.com) application that requires [node.js](https://nodejs.org) v14.

* ztncui uses argon2 for password hashing. Argon2 needs the following:
  1. g++
  2. node-gyp, which can be installed with:
```shell
sudo npm install -g node-gyp
```

* ztncui requires [ZeroTier One](https://www.zerotier.com/download.shtml) to be installed on the same machine.  This will run as the network controller to establish ZeroTier networks.

* ztncui has been developed on a Linux platform and expects the ZT home directory to be in `/var/lib/zerotier-one`.

### Installing
##### 1. Clone the repository on a machine running ZeroTier One:
```shell
git clone https://github.com/key-networks/ztncui
```

##### 2. Install the [node.js](https://nodejs.org) packages:
```shell
cd ztncui/src
npm install
```

##### 3. authtoken.secret

The app needs to know the zerotier-one authtoken.secret.

###### Make a .env file
In the root of the ztncui directory, create a `.env` file with the content:
```
ZT_TOKEN=########################
```
Where:
* ######################## is the token string.

After all edits to the `.env file` (see other options below), make the `.env` readable by the user running ztncui only:
```shell
chmod 400 .env
chown ztncui.ztncui .env
```

##### 4. Zerotier-one API port

You can specify in the `.env` file a different address for the zerotier-one API (which defaults to localhost:9993):
```
ZT_ADDR=localhost:9995
```


##### 4. Run in production mode
To run the server in production mode, add the following to the `.env` file (see 3B above):
```
NODE_ENV=production
```
Without this, the template engine always re-compiles the pug file when rendering (taking ~200 ms!)

##### 5. Copy the default passwd file
To prevent git from over-writing your password file every time you pull updates from the repository, the etc/passwd file has been added to .gitignore.  So you need to copy the default file after the first time you do a git clone.  All these things ideally need to be done with a package installer script:
```shell
cp -v etc/default.passwd etc/passwd
```

##### 6. Start the app manually:
```shell
npm start
```
This will run the app on TCP port 3000 by default.  If port 3000 is already in use, you can specify a different port in the `.env` file (see 3B above), e.g.:
```
HTTP_PORT=3456
```

##### 7. Start the app automatically
To start the app automatically, something like [PM2](http://pm2.keymetrics.io) can be used.  Install it with:
```shell
sudo npm install -g pm2
```

Add ztncui as a managed app with:
```shell
pm2 start bin/www --name ztncui
```

To detect the init system:
```shell
pm2 startup
```

PM2 will then give you a command to execute to configure automatic startup of PM2 for your system.

Save the current PM2 process list so that ztncui will restart across reboots:
```shell
pm2 save
```

##### 8. Test access on http://localhost:3000
  If the machine has a GUI and GUI web browser, then use it to access the app, otherwise use a text web browser like Lynx or a CLI web browser like curl:
```shell
curl http://localhost:3000
```
You should see the front page of the app (or the raw HTML with curl).

##### 9. Remote access via HTTPS
This app listens for HTTP requests on the looback interface (default port 3000).  It can be reverse proxied by Nginx (which can proxy the HTTP as HTTPS), or accessed over an SSH tunnel as described below.

The app can be made to listen on all interfaces for HTTP requests by setting HTTP_ALL_INTERFACES in the `.env` file, e.g.:
```
HTTP_ALL_INTERFACES=yes
```
Note that HTTP traffic is unencrypted, so this should only be done on a secure network, otherwise usernames and passwords will be exposed in plain text over the network.

The app can be made to listen on all interfaces for HTTPS requests by specifying HTTPS_PORT in the `.env` file, e.g.:
```
HTTPS_PORT=3443
```
The app can be made to listen on a specific interface for HTTPS requests by specifying HTTPS_HOST (the host name or IP address of the interface) in the `.env` file, e.g.:
```
HTTPS_HOST=12.34.56.78
```
If HTTPS_HOST is not specified, but HTTPS_PORT is specified, then the app will listen for HTTPS requests on all interfaces.

###### Summary of listening states
| Environment variable | Protocol | Listen On      | Port              |
| :------------------: | :------: | :-------:      | :--:              |
| [none]               | HTTP     | localhost      | 3000              |
| HTTP_PORT            | HTTP     | localhost      | HTTP_PORT         |
| HTTP_ALL_INTERFACES  | HTTP     | all interfaces | HTTP_PORT || 3000 |
| HTTPS_PORT           | HTTPS    | all interfaces | HTTPS_PORT        |
| HTTPS_HOST           | HTTPS    | HTTPS_HOST     | HTTPS_PORT        |


###### TLS Certificate
For HTTPS you obviously need a TLS (SSL) certificate and private key pair.  There are a few options:

1. By default, if there is no existing TLS certificate and private key pair, the RPM and DEB packages automatically generate a self-signed certificate / private key pair.

2. If you are running directly from source, then generate a self-signed certificate as follows:
   ```shell
   cd etc/tls
   openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privkey.pem -out fullchain.pem
   ```
   Fill in the required details as prompted.

   The advantage of this option is that it is quick and easy to generate the certificate / private key pair.  The disadvantage is that your web browser will give you a warning that it cannot verify the certificate.  You can override this warning and make a temporary exception.

3. Buy a certificate:

   You will need to store the private key as `etc/tls/privkey.pem` and the full certificate chain as `etc/tls/fullchain.pem`.  They need to be in PEM format.

4. Get a free certificate from Letsencrypt.org:

      a. Install certbot by following the instructions at certbot.eff.org:

        i.   For "Software" select "None of the above".
        ii.  For "System" select your OS.
        iii. Follow the instructions to install certbot on your system.

      b. Use certbot to generate a certificate in webroot mode from the root of the ztncui directory:
      ```shell
      certbot --webroot -w public -d [network_controller_fqdn]
      ```
      Where **[network_controller_fqdn]** is the FQDN that resolves back to the address of the machine running the ZeroTier network controller and ztncui.

      If certbot runs successfully, it should give you the location of your certificate, which should be something like:
      ```
      /etc/letsencrypt/live/[network_controller_fqdn]/fullchain.pem
      ```

      c. Make soft links from etc/tls to the certificate and private key under /etc/letsencrypt/live:
      ```shell
      cd etc/tls
      ln -s /etc/letsencrypt/live/[network_controller_fqdn]/fullchain.pem
      ln -s /etc/letsencrypt/live/[network_controller_fqdn]/privkey.pem
      ```

      d. Take note of the options for renewing Letsencrypt certificates and implement an appropriate strategy.

###### Test HTTPS access
Once you have a certificate at `etc/tls/fullchain.pem` and private key at `etc/tls/privkey.pem`, you should be able to access ztncui over HTTPS on the port specified by HTTPS_PORT.


##### 10. Remote access via SSH
###### SSH tunnel from Linux / Unix / macOS client
An SSH tunnel can be established with:
```shell
ssh -f user@network.controller.machine -L 3333:localhost:3000 -N
```
where:
* **network.controller.machine** is the FQDN of the machine running the ZT network controller and ztncui, and
* **user** is any user account that you have on that machine.

Once the SSH tunnel has been established, access the ztncui web interface in a web browser on your local machine at: http://localhost:3333

###### SSH tunnel from a Windows machine
On Windows you can install [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)

Open PuTTY and configure as follows:

1. Go to Connection -> SSH -> Tunnels.
2. Set **Source port** to 3333
3. Set **Destination** to localhost:3000
4. Click on the **Add** button.
5. Go to **Session** in the **Category** panel on the left.
6. Set **Host Name (or IP address)** to the FQDN of the machine running the ZT network controller and ztncui.
7. Enter a name for the configuration in **Saved Sessions** and click **Save**.
8. Click the **Open** button and log into the network controller machine.

Once the SSH tunnel has been established, access the ztncui web interface in a web browser on your local machine at: http://localhost:3333

## Usage
### User accounts
Once you have access to the web UI of ztncui, log in as user **admin** with password **password**.

You will be prompted to change the default password.

It's a good idea to create your own username and delete the default admin account.  You can do this by clicking on the **Users** tab and then the **Create user** tab.  Note that you then have to log out and log in as the new user before you can delete the default admin account.

### Networks
Click on the **Home** tab to get to the network controller home page.  From there you can click on the **Networks** tab to see the existing networks configured on the network controller (probably none if you have just set it up).

#### Create a new network
Click on the **Add network** tab to create a new ZeroTier network that is controlled by the network controller.  Give it a name and click **Create Network**.  You will then be taken back to the **Networks** page that lists all the networks on the controller.

#### Delete a network
On the **Networks** page, click the trash can icon to delete a network.  You will be warned that this action cannot be undone.  Click the **Delete** button to confirm the action.

#### Change network name
On the **Networks** page, click the name of the network to rename it.

#### Easy network setup
On the **Networks** page, click **easy setup** for the network that you want to auto-configure.  Click **Generate network address** to assign a random network address, or manually enter the network address in CIDR notation.  The start and end of the IP assignment pool will be automatically calculated, but these can be manually adjusted.  Click **Submit** to apply the configuration.  You should then get a notice that the network setup succeeded.

Note that the **easy setup** only works for IPv4 at this stage.  To set up IPv6, follow the **detail** link for a network from the **Networks** page and set up each property manually.

#### Join devices to the network
Invite users to join the network with:
```shell
sudo zerotier-cli join ################
```
where ################ is the 16-digit ZeroTier network ID.

Get the user to send you their 10-digit ZeroTier address, which they can get by running:
```shell
sudo zerotier-cli status
```

#### Authorize members on the network
On the **Networks** page, click **members** to see the devices which are trying to join the network.  Use the ZeroTier address given to you by the user to identify them and name them appropriately under **Member name**.

Then check the **Authorized** checkbox to authorize the user on the network.

If the user's device is online and you click the **Refresh** button, you should see their IP assignment being populated.

Once two or more members are authorized on the network, they should be able to connect to each other via their assigned IP addresses.

#### IP Assignments
IP assignments can be changed by clicking on the IP address in the **members** page.  Enter an IP address in the managed route subnet and click the **+** icon.  Then delete the old IP address.

#### Ethernet bridging
Ethernet bridging between virtual and physical networks can be enabled by checking the **Active bridge** checkbox on the **members** page.

#### Network detail
On the **Networks** page, click **detail** to see the detail of a network.

Note that certain properties can be set by clicking on them - e.g.:
* ipAssignmentPools
* name
* routes
* v4AssignMode
* v6AssignMode

Note that editing of certain properties, such as rules and tags, has not been implemented yet.  Please feed back on your requirements.

#### Member detail
On the network **detail** page and on the **members** page, if you click on the member ID, you will end up on the member detail page.

## Feedback
Please give us your feedback... good, bad or ugly.  Constructive criticism is welcomed.  Please use the contact form at [key-networks.com](https://key-networks.com/) - Thanks :)

## Bug and Vulnerability Reporting
Problems with ztncui can be reported using the GitHub issue tracking system.  Please use the contact form at [key-networks.com](https://key-networks.com/) to privately report potential vulnerabilities.  Thank you.

## License
The ztncui code is open source code, licensed under the GNU GPLv3, and is free to use on those terms. If you are interested in commercial licensing, please contact us via the contact form at [key-networks.com](https://key-networks.com) .

## Thanks
- @lideming for a rework and improvement of the network details page, adding DNS support, peer status/address/latency and other improvements.
- @Koromix for a fix for incompatibility with ZeroTier 1.12.
