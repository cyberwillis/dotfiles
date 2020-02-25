#!/bin/bash -e
# https://github.com/lxc/lxd-pkg-snap/blob/latest-edge/snapcraft.yaml

msg() {
	RESET='\033[0m'
	COLOR='\033[1;32m'
  	echo -e "${COLOR}: $1${RESET}"
}
#=====================================================================================
do_install_go()
{
	msg "Installing GoLang"
	if [[ ! -e "/opt/go1.11.13" ]]; then
		wget https://dl.google.com/go/go1.11.13.linux-amd64.tar.gz -O /tmp/go1.11.13.linux-amd64.tar.gz
		sudo tar -xvf /tmp/go1.11.13.linux-amd64.tar.gz -C /opt/
		sudo mv /opt/go /opt/go1.11.13
		if [ -d /usr/local/go ]; then
			sudo rm -rf /usr/local/go
		fi
		sudo ln -s /opt/go1.11.13 /usr/local/go

		mkdir -p ${HOME}/go
		export GOROOT=/usr/local/go
		export GOPATH=${HOME}/go
		export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}
	fi
}
#================================================================================
do_install_python_packages()
{
	msg "Installing python libs and system packages"
	sudo apt install -qqy build-essential git apt-file pkg-config python 
	#sudo apt install -qqy python-pip
	#sudo apt-file update
	wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
	python /tmp/get-pip.py --user
	pip install -U pip --user
	pip install gitup --user
}
#================================================================================
do_install_fs()
{
	msg "Installing File Systems"

	sudo apt-get update
	#================================================================================
	#btrfs (install)
	sudo apt install -qqy btrfs-tools
	#================================================================================
	#ceph (install)
	sudo apt install -qqy ceph-common libdb5.3
	#================================================================================
	#dqlite (build)
	sudo apt install -qqy autotools-dev libuv1 libuv1-dev
	#================================================================================
	#edk2 (build)
	sudo apt install -qqy acpica-tools qemu nasm uuid-dev 
	#================================================================================
	#libco (build)
	#================================================================================
	#libsecomp (build)
	#================================================================================
	#logrotate (inside snapcraft???)
	sudo apt install -qqy logrotate libpopt0
	#================================================================================
	#lvm (install)
	sudo apt install -qqy dmeventd lvm2 thin-provisioning-tools
	#================================================================================
	#nvidia-container (build)
	#================================================================================
	#openvswitch (install)
	sudo apt install -qqy openvswitch-switch uuid-runtime
	#================================================================================
	#qemu (build)
	sudo apt install -qqy qemu qemu-kvm virt-manager libvirt-daemon ovmf
	#================================================================================
	#qemu-ovmf-secureboot (build)
	#================================================================================
	#raft (build)
	#================================================================================
	#sqlite (build)
	#================================================================================
	#squashfs-tools-ng (build)
	#================================================================================
	#xfs (install)
	sudo apt install -qqy xfsprogs
	#================================================================================
	#xtables (install)
	sudo apt install -qqy ebtables iptables xtables-addons-common
	#================================================================================
	#xz (install)
	sudo apt install -qqy xz-utils
	#================================================================================
	#zfs-0-6
	#================================================================================
	#zfs-0-7
	#================================================================================
	#zfs-0-8
	#================================================================================
	#lxc (build)
	#================================================================================
	#lxcfs (build)
	#================================================================================
	#criu (install)
	#================================================================================
	#lxd (build)
	#================================================================================
	#lxd-migrate (build)
	#================================================================================
	#shmounts (???)
	#================================================================================
	#snapquery (???)
	#================================================================================
	#strip (???)
	#================================================================================
	#zfs-8.2
	if [[ ! -e "/etc/apt/sources.list.d/zfs.list" ]]; then
		sudo add-apt-repository ppa:jonathonf/zfs -y
		
		DISTRIBUTION=$(lsb_release -cs)
		echo "deb http://ppa.launchpad.net/jonathonf/zfs/ubuntu ${DISTRIBUTION} main" | sudo tee /etc/apt/sources.list.d/zfs.list
		echo "#deb-src http://ppa.launchpad.net/jonathonf/zfs/ubuntu ${DISTRIBUTION} main" | sudo tee -a /etc/apt/sources.list.d/zfs.list
	
		sudo apt-get update
		sudo apt install -qqy \
						spl \
						spl-dkms

		sudo apt install -qqy \
						zfs-dkms \
						libnvpair1linux \
						libuutil1linux \
						libzfs2linux \
						libzpool2linux \
						zfsutils-linux \
						zfs-zed
						#zfs-doc \

		msg "Reboot the machine and start this tool again"
		sudo reboot
	fi
}
#================================================================================
do_build_criu()
{
	#criu (https://github.com/checkpoint-restore/criu)
	#
	#DEPENDS:
	#       asciidoc libcap-dev libnet1-dev libnl-3-dev libprotobuf-c-dev libprotobuf-dev protobuf-c-compiler protobuf-compiler python xmlto
	#       libnet1 libprotobuf-c1 libbsd-dev

	msg "Building Criu"

	#Initialize	passed arguments variable
	DATE_BRANCH_CRIU=""
	INSTALL_CRIU=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_CRIU="$1"

		INSTALL_CRIU=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/criu" ]; then
		sudo apt install -qqy asciidoc libcap-dev libnet1-dev libnl-3-dev libprotobuf-c-dev libprotobuf-dev protobuf-c-compiler protobuf-compiler python xmlto
		sudo apt install -qqy libnet1 libprotobuf-c1
		sudo apt install -qqy libbsd-dev
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/criu" ]; then
		msg "Cloning Criu Repository"
		cd ${GOPATH}
		git clone https://github.com/checkpoint-restore/criu

		INSTALL_CRIU=1
	else
		msg "Checking for updates in Criu Repository"
		cd ${GOPATH}/criu

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_CRIU=1
		fi
	fi 

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_CRIU} == 1 ]]; then
		
		cd ${GOPATH}/criu

		if [[ "$(echo ${DATE_BRANCH_CRIU} 2> /dev/null)" != "" ]]; then 
			BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_CRIU} | head -n1 | cut -d" " -f1)
			msg "Building Criu (${BRANCH})"
			git checkout ${BRANCH}
		else
			msg "Building Criu branch (master)"
			git checkout master
		fi

		make -j12
		#sudo make install
	else
		msg "Nothing to update in Criu"
	fi

	
}
#================================================================================
do_install_tools()
{
	msg "Installing basic tools"
	#nano (install)
	sudo apt install -y nano
}
#================================================================================
do_build_libco()
{
	#libco (https://github.com/canonical/libco)
	#
	#DEPENDS:
	#       make

	msg "Building libco"

	#Initialize	passed arguments variable
	DATE_BRANCH_LIBCO=""
	INSTALL_LIBCO=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_LIBCO="$1"

		INSTALL_LIBCO=1
	fi

	#If this path DONT exists, install libraries
	if [[ ! -e "${GOPATH}/deps/libco" ]]; then
		sudo apt install -qqy make
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [[ ! -e "${GOPATH}/deps/libco" ]]; then
		msg "Cloning libco Repository"
		mkdir -p ${GOPATH}/deps
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/libco

		INSTALL_LIBCO=1
	else
		msg "Checking for updates in libco Repository"
		cd ${GOPATH}/deps/libco

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_LIBCO=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_LIBCO} == 1 ]]; then

		cd ${GOPATH}/deps/libco

		if [[ "$(echo ${DATE_BRANCH_LIBCO} 2> /dev/null)" != "" ]]; then 
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LIBCO} | head -n1 | cut -d" " -f1)
			msg "Building libco (${BRANCH})"
			git checkout ${BRANCH}
		else
			msg "Building libco (master)"
			git checkout master
		fi

		make -j12
		#sudo make install
	else
		msg "Nothing to update in libco"
	fi	
}
#================================================================================
do_build_raft()
{
	#raft (https://github.com/canonical/raft)
	#
	#DEPENDS:
	#       autotools-dev autoconf libtool
	#

	msg "Building Raft"

	#Initialize	passed arguments variable
	DATE_BRANCH_RAFT=""
	INSTALL_LIBRAFT=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_RAFT="$1"

		INSTALL_LIBRAFT=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/deps/raft" ]; then
		sudo apt install -y autotools-dev
		###
		sudo apt install -y autoconf libtool
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/deps/raft" ]; then
		msg "Cloning Raft Repository"
		mkdir -p ${GOPATH}/deps
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/raft

		INSTALL_LIBRAFT=1
	else
		msg "Checking for updates in Raft Repository"
		cd ${GOPATH}/deps/raft

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_LIBRAFT=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_LIBRAFT} == 1 ]]; then

		cd ${GOPATH}/deps/raft

		if [[ "$(echo ${DATE_BRANCH_RAFT} 2> /dev/null)" != "" ]]; then 
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_RAFT} | head -n1 | cut -d" " -f1)
			msg "Building Raft (${BRANCH})"
			git checkout ${BRANCH}
		else
			msg "Building Raft (master)"
			git checkout master
		fi

		autoreconf -i
		./configure
		make -j12
		#sudo make install
	else
		msg "Nothing to update in Raft"
	fi
	
}
#================================================================================
do_build_sqlite()
{
	#sqlite (https://github.com/canonical/sqlite)
	#DEPENDS: 
	#      autotools-dev tclsh
	#FLAG 
	#--enable-replication 
	#--disable-amalgamation
	#--disable-tcl

	msg "Building SQLite"

	#Initialize	passed arguments variable
	DATE_BRANCH_SQLITE=""
	INSTALL_SQLITE=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_SQLITE="$1"

		INSTALL_SQLITE=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/deps/sqlite" ]; then
		sudo apt install -y autotools-dev
		sudo apt install -y tclsh
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/deps/sqlite" ]; then
		msg "Cloning SQLite Repository"
		mkdir -p ${GOPATH}/deps
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/sqlite

		INSTALL_SQLITE=1
	else
		msg "Checking for updates in SQLite Repository"
		cd ${GOPATH}/deps/sqlite

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_SQLITE=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_SQLITE} == 1 ]]; then

		cd ${GOPATH}/deps/sqlite

		if [[ "$(echo ${DATE_BRANCH_SQLITE} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_SQLITE} | head -n1 | cut -d" " -f1)
			msg "Building SQLite (${BRANCH})"
			git checkout ${BRANCH}
		else
			msg "Building SQLite (master)"
			git checkout master
		fi

		./configure --enable-replication --disable-amalgamation --disable-tcl
		git log -1 --format="format:%ci%n" | sed -e 's/ [-+].*$$//;s/ /T/;s/^/D /' > manifest
		git log -1 --format="format:%H" > manifest.uuid
		make -j12
		#sudo make install
	else
		msg "Nothing to update in SQLite"
	fi
	
}
#================================================================================
do_build_dqlite()
{
	#dqlite (https://github.com/canonical/dqlite)

	#DEPENDS:
	#       autotools-dev libuv1 libuv1-dev
	#AFTER:
	#      libco, raft, sqlite

	msg "Building DQLite"

	#Initialize	passed arguments variable
	DATE_BRANCH_DQLITE=""
	INSTALL_DQLITE=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_DQLITE="$1"

		INSTALL_DQLITE=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/deps/dqlite" ]; then
		sudo apt install -y autotools-dev
		sudo apt install -y libuv1
		sudo apt install -y libuv1-dev
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/deps/dqlite" ]; then
		msg "Cloning DQLite Repository"
		mkdir -p ${GOPATH}/deps
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/dqlite

		INSTALL_DQLITE=1
	else
		msg "Checking for updates in DQLite Repository"
		cd ${GOPATH}/deps/dqlite

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_DQLITE=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_DQLITE} == 1 ]]; then

		cd ${GOPATH}/deps/dqlite

		if [[ "$(echo ${DATE_BRANCH_DQLITE} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_DQLITE} | head -n1 | cut -d" " -f1)
			msg "Building DQLite (${BRANCH})"
			git checkout ${BRANCH}
		else
			msg "Building DQLite (master)"

			git checkout master
		fi
		autoreconf -i
		PKG_CONFIG_PATH="${GOPATH}/deps/sqlite/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/" ./configure
		make -j12 CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/" LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs/"
		#sudo make install

		#export GOPATH=${HOME}/go
		export CGO_CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/ -I${GOPATH}/deps/dqlite/include/"
		export CGO_LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs -L${GOPATH}/deps/dqlite/.libs/"
		export LD_LIBRARY_PATH="${GOPATH}/deps/sqlite/.libs/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/.libs/:${GOPATH}/deps/dqlite/.libs/"

		#create a conf for ldconfig
		echo "${GOPATH}/deps/sqlite/.libs/"  | sudo tee /etc/ld.so.conf.d/lxd.conf
		echo "${GOPATH}/deps/libco/"         | sudo tee -a /etc/ld.so.conf.d/lxd.conf
		echo "${GOPATH}/deps/raft/.libs/"    | sudo tee -a /etc/ld.so.conf.d/lxd.conf
		echo "${GOPATH}/deps/dqlite/.libs/"  | sudo tee -a /etc/ld.so.conf.d/lxd.conf
		sudo ldconfig

		#echo 'export GOROOT=/usr/local/go' | tee ${HOME}/.dotfiles/lxd/path.zsh
		#echo 'export GOPATH=${HOME}/go'  | tee -a ${HOME}/.dotfiles/lxd/path.zsh
		#echo 'export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}' | tee -a ${HOME}/.dotfiles/lxd/path.zsh

		#echo 'export CGO_CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/ -I${GOPATH}/deps/dqlite/include/"'   | tee -a ${HOME}/.dotfiles/lxd/path.zsh
		#echo 'export CGO_LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs -L${GOPATH}/deps/dqlite/.libs/"' | tee -a ${HOME}/.dotfiles/lxd/path.zsh
		#echo 'export LD_LIBRARY_PATH="${GOPATH}/deps/sqlite/.libs/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/.libs/:${GOPATH}/deps/dqlite/.libs/"'    | tee -a ${HOME}/.dotfiles/lxd/path.zsh
	else
		msg "Nothing to update in DQLite"
	fi
}
#================================================================================
do_build_edk2()
{
	# https://github.com/tianocore/edk2
	#
	#DEPENDS:
	#       acpica-tools nasm uuid-dev
	#AFTER:
	#      qemu

	msg "Building EDK2"

	#Initialize	passed arguments variable
	DATE_BRANCH_EDK2=""
	INSTALL_EDK2=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_EDK2="$1"

		INSTALL_EDK2=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/edk2" ]; then
		sudo apt install -y acpica-tools qemu
		sudo apt install -y nasm
		sudo apt install -y uuid-dev
	fi


	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/edk2" ]; then
		msg "Cloning EDK2 Repository"
		#mkdir -p ${GOPATH}/edk2
		cd ${GOPATH}
		git clone https://github.com/tianocore/edk2
		cd ${GOPATH}/edk2
		git submodule update --init
		cd ..

		INSTALL_EDK2=1
	else
		msg "Checking for updates in EDK2 Repository"
		cd ${GOPATH}/edk2

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;
			git submodule update

			INSTALL_EDK2=1
		fi
	fi

	if [[ ${INSTALL_EDK2} == 1 ]]; then
		cd ${GOPATH}/edk2

		if [[ "$(echo ${DATE_BRANCH_EDK2} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_EDK2} | head -n1 | cut -d" " -f1)
			msg "Building EDK2 (${BRANCH})"
			git checkout ${BRANCH}
			git submodule update
		else
			msg "Building EDK2 (master)"

			git checkout master
		fi

		ARCH="X64"
		PKG="OvmfPkg/OvmfPkgX64.dsc"
		FV_CODE="OVMF_CODE"
		FV_VARS="OVMF_VARS"
		if [ "$(uname -m)" = "aarch64" ]; then
			ARCH="AARCH64"
			PKG="ArmVirtPkg/ArmVirtQemu.dsc"
			FV_CODE="QEMU_EFI"
			FV_VARS="QEMU_VARS"
		fi
		# Run in a bash sub-shell as edksetup.sh requires it
		. ./edksetup.sh
		make -j12 -C BaseTools ARCH=${ARCH}
		build -a ${ARCH} -t GCC49 -b RELEASE -p ${PKG} \
				-DNETWORK_HTTP_BOOT_ENABLE=TRUE \
				-DSECURE_BOOT_ENABLE=TRUE \
				-DFD_SIZE_2MB \
				-DTPM2_ENABLE=TRUE

		mkdir -p "${GOPATH}/share/qemu/"
		cp Build/*/*/FV/${FV_CODE}.fd "${GOPATH}/share/qemu/OVMF_CODE.fd"
      	cp Build/*/*/FV/${FV_VARS}.fd "${GOPATH}/share/qemu/OVMF_VARS.fd"

		if [ "$(uname -m)" = "aarch64" ]; then
          truncate -s 64m "${GOPATH}/share/qemu/OVMF_CODE.fd"
          truncate -s 64m "${GOPATH}/share/qemu/OVMF_VARS.fd"
      	fi
		#	cp Build/*/*/FV/${FV_CODE}.fd "${SNAPCRAFT_PART_INSTALL}/share/qemu/OVMF_CODE.fd"
		#	cp Build/*/*/FV/${FV_VARS}.fd "${SNAPCRAFT_PART_INSTALL}/share/qemu/OVMF_VARS.fd"
		#	if [ "$(uname -m)" = "aarch64" ]; then
		#		truncate -s 64m "${SNAPCRAFT_PART_INSTALL}/share/qemu/OVMF_CODE.fd"
		#		truncate -s 64m "${SNAPCRAFT_PART_INSTALL}/share/qemu/OVMF_VARS.fd"
		#	fi
		#sudo make install
	else
		msg "Nothing to update in EDK2"
	fi

}
#================================================================================
do_build_libseccomp()
{
	#libseccomp (https://github.com/seccomp/libseccomp)

	msg "Building libseccomp"

	INSTALL_LIBSECCOMP=0
	
	if [[ ! -e "${GOPATH}/libseccomp" ]]; then
		sudo apt install -y autotools-dev
	fi

	if [ ! -e "${GOPATH}/libseccomp" ]; then
		msg "Cloning libseccomp Repository"
		INSTALL_LIBSECCOMP=1

		cd ${GOPATH}
		git clone https://github.com/seccomp/libseccomp
	else
		msg "Checking for updates in libseccomp Repository"

		cd ${GOPATH}/libseccomp
		
		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_LIBSECCOMP=1
		fi
	fi

	if [[ ${INSTALL_LIBSECCOMP} == 1 ]]; then
		
		cd ${GOPATH}/libseccomp

		./autogen.sh
		./configure
		make -j12
		sudo make install
	else
		msg "Nothing to update in libseccomp"
	fi

}
#================================================================================
do_build_libnvidia_container()
{
	msg "Building libnvidia-container"
	#nvidia-container (https://github.com/NVIDIA/libnvidia-container)
	sudo apt install -y make
	sudo apt install -y bmake curl lsb-release

	###
	sudo apt install m4

	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_LIBNVIDIA="$1"
	fi

	if [ ! -d ${GOPATH}/libnvidia-container ]; then
		cd ${GOPATH}
		git clone https://github.com/NVIDIA/libnvidia-container
	fi

	cd ${GOPATH}/libnvidia-container

	git clean -xdf
	git checkout master
	git pull

	if [[ "$(echo ${DATE_BRANCH_LIBNVIDIA} 2> /dev/null)" != "" ]]; then
		BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LIBNVIDIA} | head -n1 | cut -d" " -f1)
		msg "Building libnvidia-container (${BRANCH})"
		git checkout ${BRANCH}
	else
		msg "Building libnvidia-container (HEAD)"
	fi
	make -j12
	#sudo make install
	
}
#================================================================================
do_build_qemu()
{
	# https://git.qemu.org/git/qemu.git
	#
 	#DEPENDS:
    #  bison flex pkg-config libcap-ng-dev libglib2.0-dev libpixman-1-dev libaio-dev
    #  genisoimage libmagic1 libpixman-1-0

	#AFTER:
	#  libseccomp

	#https://git.qemu.org/git/qemu.git
	#- --disable-docs
	#- --disable-slirp
	#- --disable-user
	#- --enable-attr
	#- --enable-cap-ng
	#- --enable-kvm
	#- --enable-linux-aio
	#- --enable-pie
	#- --enable-seccomp
	#- --enable-system
	#- --enable-tools
	#- --enable-vhost-crypto
	#- --enable-vhost-kernel
	#- --enable-vhost-net
	#- --enable-vhost-scsi
	#- --enable-vhost-user
	#- --enable-vhost-vsock
	#- --enable-virtfs
	#- --enable-vnc
	#- --firmwarepath=/snap/lxd/current/share/qemu/

	msg "Building Qemu"

	#Initialize	passed arguments variable
	DATE_BRANCH_QEMU=""
	INSTALL_QEMU=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_QEMU="$1"

		INSTALL_QEMU=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/qemu" ]; then
		sudo apt install -y - bison flex pkg-config libcap-ng-dev libglib2.0-dev libpixman-1-dev libaio-dev libfdt-dev
		sudo apt install -y genisoimage libmagic1 libpixman-1-0
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/qemu" ]; then
		msg "Cloning QEMU Repository"
		cd ${GOPATH}
		git clone --recurse https://git.qemu.org/git/qemu.git

		INSTALL_QEMU=1
	else
		msg "Checking for updates in QEMU Repository"
		cd ${GOPATH}/qemu

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_QEMU=1
		fi
	fi

	if [[ ${INSTALL_QEMU} == 1 ]]; then
		cd ${GOPATH}/qemu

		if [[ "$(echo ${DATE_BRANCH_QEMU} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_QEMU} | head -n1 | cut -d" " -f1)
			msg "Building QEMU (${BRANCH})"
			git checkout ${BRANCH}
			git submodule update --init --recursive
		else
			msg "Building QEMU (master)"

			git checkout master
			git submodule update --init --recursive
		fi

		# Mangle the configure a bit
		sed -i "s/^unset target_list$/target_list=\"$(uname -m)-softmmu\"/" configure
      	sed -i 's#libseccomp_minver=".*#libseccomp_minver="0.0"#g' configure
		
		mkdir build
		cd build
		# Run in a bash sub-shell as edksetup.sh requires it
		../configure \
		--disable-docs \
		--disable-slirp \
		--disable-user \
		--enable-attr \
		--enable-cap-ng \
		--enable-kvm \
		--enable-linux-aio \
		--enable-pie \
		--enable-seccomp \
		--enable-system \
		--enable-tools \
		--enable-vhost-crypto \
		--enable-vhost-kernel \
		--enable-vhost-net \
		--enable-vhost-scsi \
		--enable-vhost-user \
		--enable-vhost-vsock \
		--enable-virtfs \
		--enable-vnc \
		--prefix=/usr \
		--firmwarepath=/usr/share/OVMF/
		
		#--libseccomppath=${GOPATH}/libseccomp \
	   	#--firmwarepath=/snap/lxd/current/share/qemu/
		make -j12
		sudo make install

		#mkdir -p ${GOPATH}/share
		#cp pc-bios/efi-virtio.rom ${GOPATH}/share/qemu/
		#cp pc-bios/kvmvapic.bin ${GOPATH}/share/qemu/
	else
		msg "Nothing to update in QEmu"
	fi

}

build_qemu_ovmf_secureboot()
{
	# https://github.com/puiterwijk/qemu-ovmf-secureboot
	#
 	#DEPENDS:
    #  xorriso

	#AFTER:
	#  edk2
    #  qemu

	#https://git.qemu.org/git/qemu.git
	#- --disable-docs
	#- --disable-slirp
	#- --disable-user
	#- --enable-attr
	#- --enable-cap-ng
	#- --enable-kvm
	#- --enable-linux-aio
	#- --enable-pie
	#- --enable-seccomp
	#- --enable-system
	#- --enable-tools
	#- --enable-vhost-crypto
	#- --enable-vhost-kernel
	#- --enable-vhost-net
	#- --enable-vhost-scsi
	#- --enable-vhost-user
	#- --enable-vhost-vsock
	#- --enable-virtfs
	#- --enable-vnc
	#- --firmwarepath=/snap/lxd/current/share/qemu/

	msg "Building QEMU_OVMF"

	#Initialize	passed arguments variable
	DATE_BRANCH_QEMU_OVMF=""
	INSTALL_QEMU_OVMF=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_QEMU_OVMF="$1"

		INSTALL_QEMU_OVMF=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/qemu-ovmf-secureboot" ]; then
		sudo apt install -y xorriso
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/qemu-ovmf-secureboot" ]; then
		msg "Cloning QEMU_OVMF Repository"
		cd ${GOPATH}
		git clone --recurse https://github.com/puiterwijk/qemu-ovmf-secureboot

		INSTALL_QEMU_OVMF=1
	else
		msg "Checking for updates in QEMU_OVMF Repository"
		cd ${GOPATH}/qemu-ovmf-secureboot

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_QEMU_OVMF=1
		fi
	fi

	if [[ ${INSTALL_QEMU_OVMF} == 1 ]]; then
		cd ${GOPATH}/qemu-ovmf-secureboot

		if [[ "$(echo ${DATE_BRANCH_QEMU_OVMF} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_QEMU_OVMF} | head -n1 | cut -d" " -f1)
			msg "Building QEMU_OVMF (${BRANCH})"
			git checkout ${BRANCH}
			git submodule update --init --recursive
		else
			msg "Building QEMU_OVMF (master)"

			git checkout master
			git submodule update --init --recursive
		fi

		rm -Rf iso-root vfat-root shell.iso
		mkdir -p iso-root vfat-root/efi/boot

		cp ${GOPATH}/edk2/Build/*/*/*/Shell.efi vfat-root/efi/boot/bootx64.efi
      	cp ${GOPATH}/edk2/Build/*/*/*/EnrollDefaultKeys.efi vfat-root/
		#${GOPATH}/qemu/qemu-img convert --image-opts driver=vvfat,floppy=on,fat-type=12,label=UEFI_SHELL,dir=vfat-root iso-root/shell.img 
		qemu-img convert --image-opts driver=vvfat,floppy=on,fat-type=12,label=UEFI_SHELL,dir=vfat-root iso-root/shell.img 
		xorriso --as mkisofs -input-charset ASCII -J -rational-rock -e shell.img -no-emul-boot -o shell.iso iso-root/
		
		if [ "$(uname -m)" = "aarch64" ]; then
          sed -i ovmf-vars-generator \
              -e "s/'-machine', machinetype,/'-machine', 'virt', '-cpu', 'cortex-a57',/" \
              -e "/charserial1/d" \
              -e "s/ide-cd/scsi-cd/" \
              -e "s/'-device',$/'-device', 'virtio-scsi-pci,id=scsi', '-device',/"
			#elif [ "$(uname -m)" = "x86_64" ]; then
			#cp -f "${GOPATH}/share/qemu/kvmvapic.bin" .
			#cp  -f /usr/local/share/qemu/kvmvapic.bin .

			#cp -f /usr/share/qemu/kvmvapic.bin .
		fi

		python3 ovmf-vars-generator \
        --ovmf-binary "/usr/share/OVMF/OVMF_CODE.fd" \
        --uefi-shell-iso shell.iso \
        --ovmf-template-vars "/usr/share/OVMF/OVMF_VARS.fd" \
		--qemu-binary "qemu-system-$(uname -m)" \
        --print-output --disable-smm --skip-testing \
		"${GOPATH}/share/qemu/OVMF.fd"

		#mkdir -p "${GOPATH}/share/qemu/"
		#python3 ovmf-vars-generator \
        #--ovmf-binary "${GOPATH}/share/qemu/OVMF_CODE.fd" \
        #--uefi-shell-iso shell.iso \
        #--ovmf-template-vars "${GOPATH}/share/qemu/OVMF_VARS.fd" \
		#--qemu-binary "qemu-system-$(uname -m)" \
        #--print-output --disable-smm --skip-testing \
		#"${GOPATH}/share/qemu/OVMF_VARS.ms.fd"
		
		#--fedora-version 27 \
    	#--kernel-path /tmp/qosb.kernel \
    	#--kernel-url https://download.fedoraproject.org/pub/fedora/linux/releases/27/Everything/x86_64/os/images/pxeboot/vmlinuz \
        #--print-output --skip-testing --no-download \
		#--qemu-binary "$(uname -m)-softmmu/qemu-system-$(uname -m)" \
        #--oem-string "$(cat ${SNAPCRAFT_PROJECT_DIR}/snapcraft/etc/ubuntu-sb.crt)" \
		#--qemu-binary "${GOPATH}/qemu/$(uname -m)-softmmu/qemu-system-$(uname -m)" \
		#${GOPATH}/qemu/build/pc-bios/OVMF_VARS.ms.fd

		make -j12
		sudo make install
	else
		msg "Nothing to update in QEmu"
	fi
}
#================================================================================
do_build_squashfs_tools()
{
	sudo apt install -qqy liblzma-dev doxygen

	cd ${GOPAH}
	git clone https://github.com/AgentD/squashfs-tools-ng
	squashfs-tools-ng

	./autogenls
	./configure
	make -j12
	sudo make install
}

#================================================================================
do_build_lxc()
{
	#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=update-libLXC
	echo "                 _       _               _ _ _       ____  __  ___  ";
	echo " _   _ _ __   __| | __ _| |_ ___        | (_) |__   / /\ \/ / / __\ ";
	echo "| | | | '_ \ / _\` |/ _\` | __/ _ \  _____| | | '_ \ / /  \  / / /    ";
	echo "| |_| | |_) | (_| | (_| | ||  __/ |_____| | | |_) / /___/  \/ /___  ";
	echo " \__,_| .__/ \__,_|\__,_|\__\___|       |_|_|_.__/\____/_/\_\____/  ";
	echo "      |_|                                                           ";

	#liblxc (https://github.com/lxc/lxc)
	#
	#AFTER: 
	#      libseccomp
	#
	#DEPENDS: 
	#      autotools-dev libapparmor-dev libcap-dev 
	#      libgnutls28-dev libselinux1-dev pkg-config
	#      libpam-dev
	#
	#FLAGS
	#--disable-selinux
	#--disable-tests
	#--disable-examples
	#--disable-doc
	#--disable-tools
	#--disable-api-docs
	#--disable-bash
	#--enable-apparmor
	#--enable-seccomp
	#--enable-selinux
	#--enable-capabilities
	#--disable-memfd-rexec
	#--with-rootfs-path=/var/snap/lxd/common/lxc/
	#--libexecdir=/snap/lxd/current/libexec/

	msg "Building liblxc / lxd.lxc"

	#Initialize	passed arguments variable
	DATE_BRANCH_LXC=""
	INSTALL_LXC=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_LXC="$1"

		INSTALL_LXC=1
	fi

	#If this path DONT exists, install libraries
	if [[ ! -e "${GOPATH}/lxc" ]]; then
		sudo apt install -y autotools-dev
		sudo apt install -y libapparmor-dev libcap-dev libgnutls28-dev libselinux1-dev pkg-config
		###
		sudo apt install -y libpam-dev libssl-dev
	fi
	
	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e ${GOPATH}/lxc ]; then
		msg "Cloning libLXC Repository"
		INSTALL_LXC=1

		cd ${GOPATH}
		git clone https://github.com/lxc/lxc
	else
		msg "Checking for updates in libLXC Repository"
		cd ${GOPATH}/lxc

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
		
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_LXC=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_LXC} == 1 ]]; then
		
		cd ${GOPATH}/lxc

		sudo make uninstall
		git clean -xdf

		if [[ "$(echo ${DATE_BRANCH_LXC} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXC} | head -n1 | cut -d" " -f1)
			msg "Building libLXC branch (${BRANCH})"
			git checkout ${BRANCH}
		else
			msg "Building libLXC branch (master)"
		fi

		./autogen.sh
		PKG_CONFIG_PATH="${GOPATH}/libseccomp" ./configure --enable-pam \
					--enable-apparmor \
					--enable-seccomp \
					--enable-selinux \
					--enable-capabilities \
					--disable-memfd-rexec \
					--disable-examples \
					--disable-doc \
					--disable-api-docs

		make -j12
		sudo make install

		#create symlink for nvidia hook
		if [[ -e "/usr/local/share/lxc/hooks/nvidia" ]];then
			sudo mkdir -p /usr/share/lxc/hooks;
			sudo ln -sf /usr/local/share/lxc/hooks/nvidia /usr/share/lxc/hooks/nvidia;
		fi

	else
		msg "Nothing to update in libLXC"
	fi
}
#================================================================================
do_build_lxcfs()
{
	#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=update-LXCfs
	echo "                 _       _                 ____  __  ___  __      ";
	echo " _   _ _ __   __| | __ _| |_ ___          / /\ \/ / / __\/ _|___  ";
	echo "| | | | '_ \ / _\` |/ _\` | __/ _ \  _____ / /  \  / / /  | |_/ __| ";
	echo "| |_| | |_) | (_| | (_| | ||  __/ |_____/ /___/  \/ /___|  _\__ \ ";
	echo " \__,_| .__/ \__,_|\__,_|\__\___|       \____/_/\_\____/|_| |___/ ";
	echo "      |_|                                                         ";

	#lxcfs (https://github.com/lxc/lxcfs)
	#
	#DEPENDS:
	#      autotools-dev libfuse-dev libpam0g-dev pkg-config fuse
	#
	#FLAGS
	#--datarootdir=/snap/lxd/current/
	#--localstatedir=/var/snap/lxd/common/var/

	msg "Building lxcfs"

	#Initialize	passed arguments variable
	DATE_BRANCH_LXCFS=""
	INSTALL_LXCFS=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_LXCFS="$1"

		INSTALL_LXCFS=1
	fi

	#If this path DONT exists, install libraries
	if [[ ! -e "${GOPATH}/lxcfs" ]]; then
		sudo apt install -y autotools-dev
		sudo apt install -y fuse libfuse2 libfuse-dev
		sudo apt install -y libpam0g-dev pkg-config
	fi
	
	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/lxcfs" ]; then
		msg "Cloning LXCfs Repository"
		INSTALL_LXCFS=1

		cd ${GOPATH}
		git clone https://github.com/lxc/lxcfs
	else
		msg "Checking for updates in LXCfs Repository"
		cd ${GOPATH}/lxcfs

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);

		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;
			
			INSTALL_LXCFS=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_LXCFS} == 1 ]]; then

		# Stop the service if it exists
		if [[ "$(systemctl list-unit-files | grep lxcfs  2> /dev/null)" != "" ]]; then
			sudo systemctl stop lxcfs
		fi

		cd ${GOPATH}/lxcfs
		
		sudo make uninstall
		git clean -xdf

		if [[ "$(echo ${DATE_BRANCH_LXCFS} 2> /dev/null)" != "" ]]; then
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXCFS} | head -n1 | cut -d" " -f1)
			msg "Building lxcfs (${BRANCH}) (${DATE_BRANCH_LXCFS})"
			git checkout ${BRANCH}
		else
			msg "Building lxcfs (HEAD)"
		fi

		./bootstrap.sh;
		./configure;
		make -j12;
		sudo make install;

		# Create a service if it DONT exists
		if [[ "$(systemctl list-unit-files | grep lxcfs) 2> /dev/null" == "" ]]; then
			sudo mkdir -p /var/lib/lxcfs
			sudo ln -sf /usr/local/bin/lxcfs /usr/bin/lxcfs
		fi
		sudo systemctl daemon-reload
		sudo systemctl start lxcfs.service
		systemctl status lxcfs
	else

		msg "Nothing to update in LXCfs"
	fi
}
#==========================
do_build_lxd()
{
	#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=update-LXD
	echo "                 _       _               ____  __    ___  ";
	echo " _   _ _ __   __| | __ _| |_ ___        / /\ \/ /   /   \ ";
	echo "| | | | '_ \ / _\` |/ _\` | __/ _ \_____ / /  \  /   / /\ / ";
	echo "| |_| | |_) | (_| | (_| | ||  __/_____/ /___/  \  / /_//  ";
	echo " \__,_| .__/ \__,_|\__,_|\__\___|     \____/_/\_\/___,'   ";
	echo "      |_|                                                 ";

	# https://regex101.com/
	# https://regexr.com/
	#lxd (https://github.com/lxc/lxd)
	#
	#DEPENDS:
	#      libacl1-dev pkg-config
	#      acl dnsmasq-base ebtables iptables netbase pigz rsync squashfs-tools
	#      xdelta3 xtables-addons-common
	#
	#AFTER:
	#      liblxc, dqlite, sqlite

	msg "Building lxd"
	
	#Initialize	passed arguments variable
	DATE_BRANCH_LXD=""
	INSTALL_LXD=0
	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_LXD="$1"

		INSTALL_LXD=1
	fi

	#If this path DONT exists, install libraries
	if [ ! -e "${GOPATH}/src/github.com/lxc/lxd" ];then
		#check for GOlang too: TODO
		sudo apt install -y libacl1-dev pkg-config
		sudo apt install -y acl dnsmasq-base ebtables iptables netbase pigz rsync squashfs-tools xdelta3 xtables-addons-common
	fi

	#If this path DONT exists, clone it. Otherwise update it
	if [ ! -e "${GOPATH}/src/github.com/lxc/lxd" ]; then
		msg "Cloning LXD Repository"
		INSTALL_LXD=1

		cd ${GOPATH}
		go get -d -v github.com/lxc/lxd/lxd
	else
		msg "Checking for updates in LXD Repository"
		cd ${GOPATH}/src/github.com/lxc/lxd

		GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
		git fetch;
		GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
	
		#If has difference set variable and update master
		if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]]; then
			git checkout master
			git merge FETCH_HEAD;

			INSTALL_LXD=1
		fi
	fi

	# If have parameter set prepare to install new version or a commit
	if [[ ${INSTALL_LXD} == 1 ]]; then
		
		if [[ "$(systemctl list-unit-files | grep lxd 2> /dev/null)" != "" ]]; then
			sudo systemctl stop lxd
		fi

		#change multiple branches of dependencies
		if [[ "$(echo ${DATE_BRANCH_LXD} 2> /dev/null)" != "" ]]; then

			#Remove all dependencies
			cd ${GOPATH}/src
			gitup -e "echo" . | cut -d":" -f1 | tail -n +4 | grep -P ".*\/[^(?=(lxd))]" | xargs rm -rf 

			#Change the branch of lxd
			cd ${GOPATH}/src/github.com/lxc/lxd
			BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXD} | head -n1 | cut -d" " -f1)
			#BRANCH=$(git log --pretty=format:"%h %ci %s" --since=${DATE_BRANCH_LXD} | tail -n1 | cut -d" " -f1)
			msg "Building lxd (${BRANCH})"
			git clean -xdf
			git checkout ${BRANCH}
			
			#Download all the depencies
			make update
			
			#Change the branch of all dependencies
			for REPO in $(gitup -e "echo" . | cut -d":" -f1 | tail -n +4 | grep -P ".*\/[^(?=(lxd))]"); do 
				cd ${REPO}
				BRANCH=$(git log master --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXD} | head -n1 | cut -d" " -f1); 
				msg "Checking out lxd-dependencies (${BRANCH})"
				git checkout ${BRANCH}
			done
			
			#build
			make

		else
			
			msg "Building lxd (master)"
			#Remove all dependencies
			cd ${GOPATH}/src
			gitup -e "echo" . | cut -d":" -f1 | tail -n +4 | grep -P ".*\/[^(?=(lxd))]" | xargs rm -rf 
			#gitup -e "echo" . | cut -d":" -f1 | tail -n +4 | grep -E ".*/[^(lxd)].*" | xargs rm -rf 

			#Change the branch of lxd
			cd ${GOPATH}/src/github.com/lxc/lxd
			git clean -xdf

			#Download all the depencies
			make update

			#build
			make
		fi

		if [[ "$(systemctl list-unit-files | grep lxd) 2> /dev/null" == "" ]]; then

			cat <<EOF | tee ${GOPATH}/lxd.service
[Unit]
Description=LXD - main daemon
After=lxcfs.service
Requires=lxcfs.service
Documentation=man:lxd(1)

[Service]
User=root
ExecStart=/usr/local/bin/lxd --debug --group ${USER} --logfile=/var/log/lxd/lxd.log
ExecStartPost=/usr/local/bin/lxd waitready --timeout=600
KillMode=process
TimeoutStartSec=600
TimeoutStopSec=40
Restart=on-failure
LimitNOFILE=1048576
LimitNPROC=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF

			sudo systemctl daemon-reload
			sudo cp ${GOPATH}/lxd.service /lib/systemd/system/lxd.service
			sudo systemctl enable /lib/systemd/system/lxd.service
		fi;

	sudo systemctl start lxd.service
	systemctl status lxd.service

	fi

	#/usr/local/bin/lxd --debug --group ${USER} --logfile=/var/log/lxd/lxd.log
}

restart_lxd()
{
	sudo systemctl restart lxd;
	systemctl status lxd | head -n12
}

start_lxd()
{
	sudo systemctl start lxd;
	systemctl status lxd | head -n12
}

stop_lxd()
{
	sudo systemctl stop lxd;
	systemctl status lxd | head -n12
}

restart_lxcfs()
{
	sudo systemctl restart lxcfs;
	systemctl status lxcfs | head -n12
}

start_lxcfs()
{
	sudo systemctl start lxcfs;
	systemctl status lxcfs | head -n12
}

stop_lxcfs()
{
	sudo systemctl stop lxcfs;
	systemctl status lxcfs | head -n12
}

wipe_lxd()
{
	stop_lxd
	stop_lxcfs
	cd ${GOPATH}
	rm -rf criu deps libnvidia-container libseccompls lxc lxcfs src
}

test_lxd()
{
	if [[ "$(systemctl list-unit-files | grep lxd 2> /dev/null)" != "" ]]; then
		sudo systemctl stop lxd
	fi
	sudo ${HOME}/go/bin/lxd --debug --group ${USER} --logfile=/var/log/lxd/lxd.log
}

updown_all()
{
	if [[ "$#" -gt 0 ]]; then
		DATE_DOWNGRADE_UPGRADE_BRANCH="$1"
		do_build_criu ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_libco ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_raft ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_sqlite ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_dqlite ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_libseccomp ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_libnvidia_container ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_lxc ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_lxcfs ${DATE_DOWNGRADE_UPGRADE_BRANCH}
		do_build_lxd ${DATE_DOWNGRADE_UPGRADE_BRANCH}
	else
		do_build_criu
		do_build_libco
		do_build_raft
		do_build_sqlite
		do_build_dqlite
		do_build_libseccomp
		do_build_libnvidia_container
		do_build_lxc
		do_build_lxcfs
		do_build_lxd

	fi
}

log_lxd()
{
	export COMMAND=""
	export BUILD_NOW=0
	if [[ "$#" -gt 0 ]]; then
		if [[ "$1" == "build" ]]; then
			BUILD_NOW=1
		fi
	fi

    cd ${GOPATH}/criu
	COMMAND="do_build_criu"
    echo "Criu ($COMMAND):"
    get_log_from_folder;
    echo ""

    cd ${GOPATH}/deps/libco
	COMMAND="do_build_libco"
    echo "libco ($COMMAND):"
    get_log_from_folder;
    echo ""

	cd ${GOPATH}/deps/raft
	COMMAND="do_build_raft"
	echo "Raft ($COMMAND):"
	get_log_from_folder;
	echo "";

    cd ${GOPATH}/deps/sqlite
	COMMAND="do_build_sqlite"
    echo "SQLite ($COMMAND):"
    get_log_from_folder;
    echo ""

    cd ${GOPATH}/deps/dqlite
	COMMAND="do_build_dqlite"
    echo "DQLite ($COMMAND):"
    get_log_from_folder;
    echo ""

    cd ${GOPATH}/libseccomp
	COMMAND="do_build_libseccomp"
    echo "libseccomp ($COMMAND):"
    get_log_from_folder;
    echo ""

    cd ${GOPATH}/libnvidia-container
	COMMAND="do_build_libnvidia_container"
    echo "LibNvidia-Container ($COMMAND):"
    get_log_from_folder;
    echo ""

	cd ${GOPATH}/lxc
	COMMAND="do_build_lxc"
	echo "libLXC ($COMMAND):"
	get_log_from_folder;
	echo ""

	cd ${GOPATH}/lxcfs
	COMMAND="do_build_lxcfs"
	echo "LXCfs ($COMMAND):"
	get_log_from_folder;
	echo ""

	cd ${GOPATH}/src/github.com/lxc/lxd
	COMMAND="do_build_lxd"
	echo "LXD ($COMMAND):"
	get_log_from_folder;
	echo ""

	cd ${HOME}
}

get_log_from_folder()
{
	GIT_FORMAT_REMOTE=" - %C(magenta)Origin : %C(yellow)%h %C(magenta)%ci %C(magenta)%s"
	GIT_FORMAT_LOCAL=" - %C(reset)Master : %C(yellow)%h %C(reset)%ci %C(reset)%s"
	GIT_FORMAT_ACTUAL_LOCAL=" - %C(reset)       : %C(yellow)%h %C(red)%ci %C(reset)%s" 
	GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
	GITLOG_ACTUAL_LOCAL=$(git log -n 1 --pretty=%H);
	git fetch;
	GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
	if [[ ${GITLOG_LOCAL} != ${GITLOG_REMOTE} ]]; then
		git log origin/master --pretty=format:"${GIT_FORMAT_REMOTE}" -n1
		git log master --pretty=format:"${GIT_FORMAT_LOCAL}" -n1
		if [[ ${GITLOG_LOCAL} != ${GITLOG_ACTUAL_LOCAL} ]]; then
			git log --pretty=format:"${GIT_FORMAT_ACTUAL_LOCAL}" -n1
		fi
		#build if passed eny parameter
		if [[ ${BUILD_NOW} == 1 ]]; then
			eval "${COMMAND}"
		fi
	else
		git log master --pretty=format:"${GIT_FORMAT_LOCAL}" -n1	
		if [[ ${GITLOG_LOCAL} != ${GITLOG_ACTUAL_LOCAL} ]]; then
			git log --pretty=format:"${GIT_FORMAT_ACTUAL_LOCAL}" -n1
		fi
	fi
}