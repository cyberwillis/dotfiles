check_libsecomp()
{
	msg "Manual building libseccomp"
	if [[ ! -e "${GOPATH}/libseccomp" ]];then
		cd ${GOPATH}/deps
		git clone https://github.com/seccomp/libseccomp
		cd ${GOPATH}/libseccomp
	else
		git clean -xdf
		cd ${GOPATH}/libseccomp
		git pull	
	fi

	./autogen.sh
	./configure
	make -j12
	sudo make install
}


do_build_liblxc(){

	pushd ${GOPATH}/lxc;

	GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
	git fetch;
	GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);

	if [[ ${REBUILD} == "setup" ]];then

		sudo rm -rf /etc/subuid 
		sudo rm -rf /etc/subgid
		echo "$USER:1000000:65536" | sudo tee -a /etc/subuid /etc/subgid
		echo "root:1000000:65536" | sudo tee -a /etc/subuid /etc/subgid
		sudo usermod --append --groups lxd $USER

		./autogen.sh;
		./configure --enable-pam;
		
		sleep 3s;
		
		make -j12;
		
		sleep 3s;

		sudo make install;

		#If NVIDIA-CONTAINER-RUNTIME is installed
		if [[ -e "/usr/local/share/lxc/hooks/nvidia" ]];then
			sudo mkdir -p /usr/share/lxc/hooks;
			sudo ln -s /usr/local/share/lxc/hooks/nvidia /usr/share/lxc/hooks/nvidia;
		fi

	elif [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" || ${REBUILD} == "rebuild" ]];
	then
		msg "Uninstall libLXC";
		#sudo make uninstall;

		msg "Update sources libLXC";
		git merge FETCH_HEAD;
		git clean -xdf;

		msg "Configure libLXC";
		./autogen.sh;
		#Ubuntu
		./configure --enable-pam \
		            --enable-apparmor \
                    --enable-seccomp \
                    --enable-selinux \
                    --enable-capabilities
		#RedHat
		#./configure --enable-pam --libdir=/usr/lib64
		sleep 3s;

		msg "Compile libLXC";
		make -j12;
		sleep 3s;
		
		msg "Install libLXC";
		sudo make install;
	else
		msg "Nothing to do";
	fi;

	popd;

}

build_liblxc()
{

#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=update-libLXC
echo "                 _       _               _ _ _       ____  __  ___  ";
echo " _   _ _ __   __| | __ _| |_ ___        | (_) |__   / /\ \/ / / __\ ";
echo "| | | | '_ \ / _\` |/ _\` | __/ _ \  _____| | | '_ \ / /  \  / / /    ";
echo "| |_| | |_) | (_| | (_| | ||  __/ |_____| | | |_) / /___/  \/ /___  ";
echo " \__,_| .__/ \__,_|\__,_|\__\___|       |_|_|_.__/\____/_/\_\____/  ";
echo "      |_|                                                           ";

RESET='\033[0m';
COLOR='\033[1;32m';

REBUILD=""

if [[ "$#" -gt 0 ]];then
	if [[ "$1" == "rebuild" ]];then
		REBUILD="$1"
	fi
fi

if [[ ! -e "${GOPATH}/lxc" ]]; then

	sudo apt purge liblxc1 -y
	sudo apt install -qy acl autoconf automake autotools-dev build-essential dnsmasq-base git libacl1-dev libcap-dev libtool libuv1-dev m4 make pkg-config rsync squashfs-tools tar tcl xz-utils ebtables libsqlite3-dev
	sudo apt install -qy libpam-cracklib libpam-doc libpam-modules libpam-modules-bin libpam-runtime libpam0g libpam0g-dev 
	
	#snapcraft.yaml -> build-packages
	sudo apt install -qy libseccomp-dev 
	sudo apt install -qy libapparmor-dev libcap-dev libgnutls28-dev libselinux1-dev 

	#sudo yum install pam=devel libcgroup-pam -y

	check_libsecomp;

	cd ${GOPATH}
	git clone https://github.com/lxc/lxc.git
	
	REBUILD="setup"
	do_build_liblxc;

else
	do_build_liblxc;
fi
}
