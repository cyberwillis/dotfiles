#!/bin/sh
#
# Usage: aptmirror
aptmirror()
{
if [[ ! -e "/etc/apt/sources.bak" ]];then
    sudo mv /etc/apt/sources.list  /etc/apt/sources.bak
fi;

export RELEASE=$(cat /etc/lsb-release  | grep CODENAME | cut -d"=" -f2)

cat <<EOF | sudo tee /etc/apt/sources.list
deb mirror://mirrors.ubuntu.com/mirrors.txt ${RELEASE} main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt ${RELEASE}-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt ${RELEASE}-backports main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt ${RELEASE}-security main restricted universe multiverse
EOF
}

freemem()
{
    echo "Free Up Unused Memory (Ubuntu and LinuxMint) used or cached memories (page cache, inodes, and dentries, etc)"
    sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
}