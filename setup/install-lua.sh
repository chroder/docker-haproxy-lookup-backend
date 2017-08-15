#!/bin/sh
set -x
set -e

buildDeps='curl gcc libc6-dev liblua5.3-dev libpcre3-dev libssl-dev lua5.3 m4 make unzip'

apt-get update
apt-get install -y ca-certificates
apt-get install -y $buildDeps --no-install-recommends

curl -OL https://luarocks.org/releases/${LUAROCKS_INSTALL}.tar.gz
tar xzf $LUAROCKS_INSTALL.tar.gz
mv $LUAROCKS_INSTALL $TMP_LOC
rm $LUAROCKS_INSTALL.tar.gz

cd $TMP_LOC

./configure \
  --with-lua=$WITH_LUA \
  --with-lua-include=$LUA_INCLUDE \
  --with-lua-lib=$LUA_LIB

make build
make install

cd /
rm $TMP_LOC -rf

/usr/local/bin/luarocks install http

# Not sure why this is necessary!
ln -s /usr/local/share/lua/5.3/http_0_2_0-http /usr/local/share/lua/5.3/http

/usr/local/bin/luarocks install lua-lru

apt-get purge -y --auto-remove $buildDeps
