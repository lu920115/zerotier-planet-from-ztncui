#!/bin/bash

cd /opt/key-networks/ztncui

if [ -z $MYADDR ]; then
    echo "Set Your IP Address to continue."
    echo "If you don't do that, I will automatically detect."
    MYEXTADDR=$(curl --connect-timeout 5 ip.sb)
    if [ -z $MYEXTADDR ]; then
        MYINTADDR=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
        MYADDR=${MYINTADDR}
    else
        MYADDR=${MYEXTADDR}
    fi
    echo "YOUR IP: ${MYADDR}"
fi

MYDOMAIN=${MYDOMAIN:-ztncui.docker.test}   # Used for minica
ZTNCUI_PASSWD=${ZTNCUI_PASSWD:-admin}   # Used for argon2g
MYADDR=${MYADDR}
HTTP_ALL_INTERFACES=${HTTP_ALL_INTERFACES}
HTTP_PORT=${HTTP_PORT:-3000}
HTTPS_PORT=${HTTPS_PORT:-3443}

while [ ! -f /var/lib/zerotier-one/authtoken.secret ]; do
    echo "ZT1 AuthToken is not found... Wait for ZT1 to start..."
    sleep 2
done
chown zerotier-one:zerotier-one /var/lib/zerotier-one/authtoken.secret
chmod 640 /var/lib/zerotier-one/authtoken.secret

cd /opt/key-networks/ztncui

echo "NODE_ENV=production" > /opt/key-networks/ztncui/.env
echo "MYADDR=$MYADDR" >> /opt/key-networks/ztncui/.env
echo "HTTP_PORT=$HTTP_PORT" >> /opt/key-networks/ztncui/.env
if [ ! -z $HTTP_ALL_INTERFACES ]; then
  echo "HTTP_ALL_INTERFACES=$HTTP_ALL_INTERFACES" >> /opt/key-networks/ztncui/.env
else
  [ ! -z $HTTPS_PORT ] && echo "HTTPS_PORT=$HTTPS_PORT" >> /opt/key-networks/ztncui/.env
fi

echo "ZTNCUI ENV CONFIGURATION: "
cat /opt/key-networks/ztncui/.env

mkdir -p /opt/key-networks/ztncui/etc/storage
mkdir -p /opt/key-networks/ztncui/etc/tls
mkdir -p /opt/key-networks/ztncui/etc/myfs # for planet files

# Password handling: support both new install and upgrade
if [ ! -f /opt/key-networks/ztncui/etc/passwd ]; then
    echo "Default Password File Not Exists... Generating with default password 'admin'..."
    mkdir -p /opt/key-networks/ztncui/etc
    # Use Node.js argon2 module to generate the initial password hash
    node -e "
const argon2 = require('argon2');
(async () => {
  const hash = await argon2.hash('admin');
  const passwd = { admin: { name: 'admin', pass_set: false, hash: hash } };
  require('fs').writeFileSync('/opt/key-networks/ztncui/etc/passwd', JSON.stringify(passwd));
  console.log('Default password file created. Username: admin, Password: admin');
})();
"
    echo "You will be required to change the password on first login."
else
    echo "Existing password file detected. Keeping existing credentials."
    echo "If you forgot your password, delete /opt/key-networks/ztncui/etc/passwd and restart the container."
fi

if [ ! -f /opt/key-networks/ztncui/etc/tls/fullchain.pem ] || [ ! -f /opt/key-networks/ztncui/etc/tls/privkey.pem ]; then
    echo "Cannot detect TLS Certs, Generating..."
    cd /opt/key-networks/ztncui/etc/tls
    openssl req -x509 -newkey rsa:2048 -keyout privkey.pem -out fullchain.pem -days 365 -nodes -subj "/CN=$MYDOMAIN"
    cd ../../
fi

chown -R zerotier-one:zerotier-one /opt/key-networks/ztncui

unset ZTNCUI_PASSWD
exec gosu zerotier-one:zerotier-one node ./bin/www
