#!/bin/bash -ex

# On a newly-opened PR, I've seen $GITHUB_SHA gets populated with a commit
# that can't actually be checked out. The Action passes us a value for the
# latest commit SHA for the source branch to cover that case, so use that
# instead when it's there.
if [ -z "$PULL_REQUEST_HEAD_SHA" ]; then
  PACKAGE_SHA="$GITHUB_SHA"
else
  PACKAGE_SHA="$PULL_REQUEST_HEAD_SHA"
fi

# Alas, we must compile Zeek because I've found the binary distributions are
# not compiled with libmaxminddb.
apt-get update
apt-get install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev libmaxminddb-dev
git clone --recursive https://github.com/zeek/zeek zeek-src
cd zeek-src
./configure --prefix=/usr/local/zeek
make -j$(nproc)
make -j$(nproc) install

# Add Zeek Package Manager and current revision of the geoip-conn package
pip install zkg
export PATH="/usr/local/zeek/bin:$PATH"
zkg autoconfig
zkg install --force geoip-conn --version "$PACKAGE_SHA"
echo '@load packages' | tee -a /usr/local/zeek/share/zeek/site/local.zeek

# Do a lookup of an IP that's known to have a stable location.
zeek -e "print lookup_location(199.83.220.115);" local | grep "San Francisco"
