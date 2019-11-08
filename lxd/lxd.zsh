#!/bin/bash -e

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
	#lvm (install)
	sudo apt install -qqy dmeventd lvm2 thin-provisioning-tools
	#================================================================================
	#openvswitch
	sudo apt install -qqy openvswitch-switch uuid-runtime
	#================================================================================
	#xfs
	sudo apt install -qqy xfsprogs
	#================================================================================
	#zfs-8.2
	if [[ ! -e "/etc/apt/sources.list.d/zfs.list" ]]; then
		sudo add-apt-repository ppa:jonathonf/zfs -y
		
		#DISTRIBUTION=$(lsb_release -cs)
		#echo "deb http://ppa.launchpad.net/jonathonf/zfs/ubuntu ${DISTRIBUTION} main" | sudo tee /etc/apt/sources.list.d/zfs.list
		#echo "#deb-src http://ppa.launchpad.net/jonathonf/zfs/ubuntu ${DISTRIBUTION} main" | sudo tee -a /etc/apt/sources.list.d/zfs.list
	
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
	msg "Building Criu"
	#criu (https://github.com/checkpoint-restore/criu)
	sudo apt install -qqy asciidoc libcap-dev libnet1-dev libnl-3-dev libprotobuf-c-dev libprotobuf-dev protobuf-c-compiler protobuf-compiler python xmlto
	sudo apt install -qqy libnet1 libprotobuf-c1

	# search for broken links
	#apt-file search /netlink/netlink.h
	###
	sudo apt install -qqy libbsd-dev

	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_CRIU="$1"
	fi

	if [ ! -d "${GOPATH}/criu" ]; then
		cd ${GOPATH}
		git clone https://github.com/checkpoint-restore/criu
	fi 

	cd ${GOPATH}/criu
	git clean -xdf
	git checkout master
	git pull
	msg "(${DATE_BRANCH_CRIU})"
	if [[ "$(echo ${DATE_BRANCH_CRIU} 2> /dev/null)" != "" ]]; then 
		BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_CRIU} | head -n1 | cut -d" " -f1)
		msg "Building Criu (${BRANCH})"
		git checkout ${BRANCH}
	else
		msg "Building Criu (HEAD)"
	fi
	make -j12
	#sudo make install
	
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
	msg "Building libco"
	#libco (https://github.com/canonical/libco)
	sudo apt install -qqy make

	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_LIBCO="$1"
	fi

	mkdir -p ${GOPATH}/deps
	if [[ ! -d "${GOPATH}/deps/libco" ]]; then
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/libco
	fi

	cd ${GOPATH}/deps/libco
	git clean -xdf
	git checkout master
	git pull
	if [[ "$(echo ${DATE_BRANCH_LIBCO} 2> /dev/null)" != "" ]]; then 
		BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LIBCO} | head -n1 | cut -d" " -f1)
		msg "Building libco (${BRANCH})"
		git checkout ${BRANCH}
	else
		msg "Building libco (HEAD)"
	fi
	make -j12
	#sudo make install
	
}
#================================================================================
do_build_raft()
{
	msg "Building raft"
	#raft (https://github.com/canonical/raft)
	sudo apt install -y autotools-dev
	###
	sudo apt install -y autoconf libtool

	mkdir -p ${GOPATH}/deps
	if [ ! -d "${GOPATH}/deps/raft" ]; then
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/raft
	fi

	cd ${GOPATH}/deps/raft
	git clean -xdf
	git checkout master
	git pull
	#if [[ "$(echo ${DATE_BRANCH_RAFT} 2> /dev/null)" != "" ]]; then 
	#	BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_RAFT} | head -n1 | cut -d" " -f1)
	#	msg "Building raft (${BRANCH})"
	#	git checkout ${BRANCH}
	#else
		msg "Building raft (HEAD)"
	#fi
	autoreconf -i
	./configure
	make -j12
	#sudo make install
	
}
#================================================================================
do_build_sqlite()
{
	msg "Building sqlite"
	#sqlite (https://github.com/canonical/sqlite)
	#plugin
	sudo apt install -y autotools-dev
	#stage-packages
	sudo apt install -y tclsh
	#FLAG 
	#--enable-replication

	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_SQLITE="$1"
	fi

	mkdir -p ${GOPATH}/deps
	if [ ! -d "${GOPATH}/deps/sqlite" ]; then
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/sqlite
	fi

	cd ${GOPATH}/deps/sqlite
	git clean -xdf
	git checkout master
	git pull
	if [[ "$(echo ${DATE_BRANCH_SQLITE} 2> /dev/null)" != "" ]]; then
		BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_SQLITE} | head -n1 | cut -d" " -f1)
		msg "Building sqlite (${BRANCH})"
		git checkout ${BRANCH}
	else
		msg "Building sqlite (HEAD)"
	fi
	./configure --enable-replication --disable-amalgamation --disable-tcl
	git log -1 --format="format:%ci%n" | sed -e 's/ [-+].*$$//;s/ /T/;s/^/D /' > manifest
	git log -1 --format="format:%H" > manifest.uuid
	make -j12
	#sudo make install
	
}
#================================================================================
do_build_dqlite()
{
	msg "Building dqlite"
	#dqlite (https://github.com/canonical/dqlite)
	#AFTER:
	#      libco, raft, sqlite
	sudo apt install -y autotools-dev
	sudo apt install -y libuv1
	sudo apt install -y libuv1-dev

	if [[ "$#" -gt 0 ]]; then
		DATE_BRANCH_DQLITE="$1"
	fi

	mkdir -p ${GOPATH}/deps
	if [ ! -d "${GOPATH}/deps/dqlite" ]; then
		cd ${GOPATH}/deps
		git clone https://github.com/canonical/dqlite
	fi

	cd ${GOPATH}/deps/dqlite
	git clean -xdf
	git checkout master
	git pull
	if [[ "$(echo ${DATE_BRANCH_DQLITE} 2> /dev/null)" != "" ]]; then
		BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_DQLITE} | head -n1 | cut -d" " -f1)
		msg "Building dqlite (${BRANCH})"
		git checkout ${BRANCH}
	else
		msg "Building dqlite (HEAD)"
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

	echo 'export GOROOT=/usr/local/go' | tee ${HOME}/.dotfiles/lxd/path.zsh
	echo 'export GOPATH=${HOME}/go'  | tee -a ${HOME}/.dotfiles/lxd/path.zsh
	echo 'export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}' | tee -a ${HOME}/.dotfiles/lxd/path.zsh

	echo 'export CGO_CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/ -I${GOPATH}/deps/dqlite/include/"'   | tee -a ${HOME}/.dotfiles/lxd/path.zsh
	echo 'export CGO_LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs -L${GOPATH}/deps/dqlite/.libs/"' | tee -a ${HOME}/.dotfiles/lxd/path.zsh
	echo 'export LD_LIBRARY_PATH="${GOPATH}/deps/sqlite/.libs/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/.libs/:${GOPATH}/deps/dqlite/.libs/"'    | tee -a ${HOME}/.dotfiles/lxd/path.zsh
}
#================================================================================
do_build_libseccomp()
{
	msg "Building libseccomp"
	#libseccomp (https://github.com/seccomp/libseccomp)
	sudo apt install -y autotools-dev

	if [ ! -d "${GOPATH}/libseccomp" ]; then
		cd ${GOPATH}
		git clone https://github.com/seccomp/libseccomp
	fi

	cd ${GOPATH}/libseccomp
	git clean -xdf
	git checkout master
	git pull
	#if [[ "$(echo ${DATE_BRANCH_LIBSECCOMP} 2> /dev/null)" != "" ]]; then
	#	BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LIBSECCOMP} | head -n1 | cut -d" " -f1)
	#	msg "Building libseccomp (${BRANCH})"
	#	git checkout ${BRANCH}
	#else
		msg "Building libseccomp (HEAD)"
	#fi
	./autogen.sh
	./configure
	make -j12
	#sudo make install
	
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
		BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LIBNVIDIA} | head -n1 | cut -d" " -f1)
		msg "Building libnvidia-container (${BRANCH})"
		git checkout ${BRANCH}
	else
		msg "Building libnvidia-container (HEAD)"
	fi
	make -j12
	#sudo make install
	
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
		sudo apt install -y libpam-dev
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
			BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXC} | head -n1 | cut -d" " -f1)
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
		sudo apt install -y libfuse-dev libpam0g-dev pkg-config
		sudo apt install -y fuse
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
			BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXCFS} | head -n1 | cut -d" " -f1)
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
			gitup -e "echo" . | cut -d":" -f1 | grep -E ".*/[^(lxd)].*" | xargs rm -rf 

			#Change the branch of lxd
			cd ${GOPATH}/src/github.com/lxc/lxd
			BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXD} | head -n1 | cut -d" " -f1)
			#BRANCH=$(git log --pretty=format:"%h %ci %s" --since=${DATE_BRANCH_LXD} | tail -n1 | cut -d" " -f1)
			msg "Building lxd (${BRANCH})"
			git clean -xdf
			git checkout ${BRANCH}
			
			#Download all the depencies
			make update
			
			#Change the branch of all dependencies
			for REPO in $(gitup -e "echo" . | cut -d":" -f1 | grep -E ".*/[^(lxd)].*"); do 
				cd ${REPO}
				BRANCH=$(git log --pretty=format:"%h %ci %s" --until=${DATE_BRANCH_LXD} | head -n1 | cut -d" " -f1); 
				msg "Checking out lxd-dependencies (${BRANCH})"
				git checkout ${BRANCH}
			done
			
			#build
			make

		else
			
			#Remove all dependencies
			cd ${GOPATH}/src
			gitup -e "echo" . | cut -d":" -f1 | grep -E ".*/[^(lxd)].*" | xargs rm -rf 

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

whipe_lxd()
{
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




#=========================================================================================================

#Depricated
check_libuv()
{
	msg "Manual building libuv"
	if [[ ! -e "${GOPATH}/deps/libuv" ]];then
		cd ${GOPATH}/deps
		git clone https://github.com/libuv/libuv
		cd ${GOPATH}/deps/libuv
		./autogen.sh
		./configure
		make -j12
		sudo make install
	fi
}
#Depricated
check_sqlite()
{
	msg "Manual building sqlite"
	if [[ ! -e "${GOPATH}/deps/sqlite" ]];then
		cd ${GOPATH}/deps
		git clone https://github.com/CanonicalLtd/sqlite
		cd ${GOPATH}/deps/sqlite
		./configure --enable-replication --disable-amalgamation --disable-tcl
		git log -1 --format="format:%ci%n" | sed -e 's/ [-+].*$$//;s/ /T/;s/^/D /' > manifest
		git log -1 --format="format:%H" > manifest.uuid
		make -j12
	fi
}
#Depricated
check_libco()
{
	msg "Manual building libco"
	if [[ ! -e "${GOPATH}/deps/libco" ]];then
		cd ${GOPATH}/deps
		git clone https://github.com/freeekanayaka/libco
		cd ${GOPATH}/deps/libco
		make
	fi
}
#Depricated
check_raft()
{
	msg "Manual building raft"
	if [[ ! -e "${GOPATH}/deps/raft" ]];then
		cd ${GOPATH}/deps
		git clone https://github.com/CanonicalLtd/raft
		cd ${GOPATH}/deps/raft
		autoreconf -i
		./configure
		make -j12
	fi
}
#Depricated
check_dqlite()
{
	msg "Manual building dqlite"
	if [[ ! -e "${GOPATH}/deps/dqlite" ]];then
		cd ${GOPATH}/deps
		git clone https://github.com/CanonicalLtd/dqlite
		cd ${GOPATH}/deps/dqlite
		autoreconf -i
		PKG_CONFIG_PATH="${GOPATH}/deps/sqlite/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/" ./configure
		make -j12 CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/" LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs/"

		#This step was put in $HOME/.dotfiles/lxd/path.zsh
		#fix it at environment (for next boot) put in 
		#echo "export CGO_CFLAGS=\"-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/ -I${GOPATH}/deps/dqlite/include/\""   | sudo tee -a /etc/environment
		#echo "export CGO_LDFLAGS=\"-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs -L${GOPATH}/deps/dqlite/.libs/\"" | sudo tee -a /etc/environment
		#echo "export LD_LIBRARY_PATH=\"${GOPATH}/deps/sqlite/.libs/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/.libs/:${GOPATH}/deps/dqlite/.libs/\""    | sudo tee -a /etc/environment
	fi
}
#Depricated
do_path_config_tools()
{
	#fast register after build
	export CGO_CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/ -I${GOPATH}/deps/dqlite/include/"
	export CGO_LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs -L${GOPATH}/deps/dqlite/.libs/"
	export LD_LIBRARY_PATH="${GOPATH}/deps/sqlite/.libs/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/.libs/:${GOPATH}/deps/dqlite/.libs/"

	#create a conf for ldconfig
	echo "${GOPATH}/deps/sqlite/.libs/"  | sudo tee /etc/ld.so.conf.d/lxd.conf
	echo "${GOPATH}/deps/libco/"         | sudo tee -a /etc/ld.so.conf.d/lxd.conf
	echo "${GOPATH}/deps/raft/.libs/"    | sudo tee -a /etc/ld.so.conf.d/lxd.conf
	echo "${GOPATH}/deps/dqlite/.libs/"  | sudo tee -a /etc/ld.so.conf.d/lxd.conf
	sudo ldconfig
}

build_lxcbranch()
{
	if [[ "$#" -gt 0 ]]; then
		LXC_BRANCH="$1"
		cd ${HOME}/go/lxc
		sudo systemctl stop lxd
		sudo make uninstall
		git clean -xdf
		git checkout ${LXC_BRANCH}
		./autogen.sh
		./configure --enable-pam \
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
		sudo systemctl start lxd
	else
		echo "Parameter not found"
	fi

	
}



#Depricated
do_build_lxd_old(){

	pushd ${GOPATH}/src/github.com/lxc/lxd;

	LAST_GOOD_COMMIT=$(git log -n 1 --pretty=%H)

	GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
	git fetch;
	GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);
	
	#If not master branch get the hash, to compile later
	BRANCH=$(git branch | grep "\*" | cut -d" " -f2)
	if [[ ${BRANCH} != "master" ]];then
		BRANCH=$(git log --oneline -n1 | cut -d" " -f1)
	fi

	if [[ ${REBUILD} == "setup" ]];then

		mkdir -p ${GOPATH}/deps

		check_libuv;
		check_sqlite;
		check_libco;
		check_raft;
		check_dqlite;
		do_path_config_tools;

		msg "Updating LXD dependencies";
        cd ${GOPATH}/src/github.com/lxc/lxd;
		make update;
		msg "This is the first setup so 'deps' was manually built, skipping to build.";
		#make deps;
		msg "building LXD";
		make;

		cd ${GOPATH}
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
		sudo mkdir -p /var/log/lxd
		sudo chown ${USER}:${USER} /var/log/lxd

		sudo ln -s ${GOPATH}/bin/lxd /usr/local/bin/lxd -f

		sudo systemctl daemon-reload
		sudo cp ${GOPATH}/lxd.service /lib/systemd/system/lxd.service
		sudo systemctl enable /lib/systemd/system/lxd.service

		sudo systemctl start lxd
		systemctl status lxd
		msg "Restart and manually start the service"


	elif [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" || ${REBUILD} == "rebuild" || ${BRANCH} != "master" ]];
	then

		cd ${GOPATH}/src/github.com/lxc/lxd;

		sudo systemctl stop lxd;

		msg "Update sources LXD";

		if [[ ${BRANCH} != "master" ]]; then
			git checkout master;
			git merge FETCH_HEAD;
			git checkout ${BRANCH};
		else
			git merge FETCH_HEAD;
		fi

		msg "Install LXD";
		make update;

		msg "If something wrong happens execute the following: git checkout ${LAST_GOOD_COMMIT} && make deps"
		make deps;

		msg "If something wrong happens execute the following: git checkout ${LAST_GOOD_COMMIT} && make"
		make;

		sudo systemctl start lxd;
	else
		msg "Nothing to do";
	fi

	popd;

}

#Depricated
build_lxd_old()
{

	#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=update-LXD
	echo "                 _       _               ____  __    ___  ";
	echo " _   _ _ __   __| | __ _| |_ ___        / /\ \/ /   /   \ ";
	echo "| | | | '_ \ / _\` |/ _\` | __/ _ \_____ / /  \  /   / /\ / ";
	echo "| |_| | |_) | (_| | (_| | ||  __/_____/ /___/  \  / /_//  ";
	echo " \__,_| .__/ \__,_|\__,_|\__\___|     \____/_/\_\/___,'   ";
	echo "      |_|                                                 ";

	RESET='\033[0m';
	COLOR='\033[1;32m';

	REBUILD=0

	if [[ "$#" -gt 0 ]];then
		if [[ "$1" == "rebuild" ]];then
				REBUILD="$1"
		fi
	fi

	if [[ ! -e "${GOPATH}/src/github.com/lxc/lxd" ]]; then

		if [[ "$(env | grep ${GOPATH} 2> /dev/null)" == "" || ! -e "${HOME}/go" ]];then

			wget https://dl.google.com/go/go1.12.6.linux-amd64.tar.gz -O /tmp/go1.12.6.linux-amd64.tar.gz
			sudo tar -xvf /tmp/go1.12.6.linux-amd64.tar.gz -C /opt/
			sudo mv /opt/go /opt/go1.12.6
			sudo rm -rf /usr/local/go
			sudo ln -s /opt/go1.12.6 /usr/local/go

			mkdir -p ${HOME}/go
			
			export GOROOT=/usr/local/go
			export GOPATH=${HOME}/go
			export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}
		fi

		sudo apt remove -y golang
		
		sudo apt purge lxd -qy

		sudo apt install -qy acl autoconf automake autotools-dev build-essential dnsmasq-base git \
								libacl1-dev libcap-dev libtool libuv1-dev m4 make pkg-config rsync \
								squashfs-tools tar tcl xz-utils ebtables libsqlite3-dev 
		
		sudo apt install -qy libapparmor-dev libseccomp-dev

		sudo apt install -qy lvm2 thin-provisioning-tools
		sudo apt install -qy btrfs-tools

		sudo apt install -qy curl gettext jq sqlite3 uuid-runtime bzr socat

		sudo apt-get install -qy tclsh libuv1-dev
		
		#building the LXD
		go get -d -v github.com/lxc/lxd/lxd
		
		REBUILD="setup"
		do_build_lxd_old;

	else
		do_build_lxd_old;
	fi
}