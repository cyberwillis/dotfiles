do_build_lxcfs(){

	cd ${GOPATH}/lxcfs;

	GITLOG_LOCAL=$(git log master -n 1 --pretty=%H);
	git fetch;
	GITLOG_REMOTE=$(git log origin/master -n 1 --pretty=%H);

	if [[ ${REBUILD} == "setup" ]];then

		msg "Instal LXCfs"
		./bootstrap.sh;
		./configure;
		make -j12;
		sudo make install;

		sudo mkdir -p /var/lib/lxcfs
		sudo ln -s /usr/local/bin/lxcfs /usr/bin/lxcfs -f
		sudo systemctl daemon-reload
		sudo systemctl start lxcfs.service
		systemctl status lxcfs

	elif [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" || ${REBUILD} == "rebuild" ]];
	then
		sudo systemctl stop lxd;
		sudo systemctl stop lxcfs;

		msg "Uninstall LXCfs";
		#sudo make uninstall;

		msg "Update sources LXCfs";
		git merge FETCH_HEAD;
		git clean -xdf;

		msg "Configure LXCfs";
		./bootstrap.sh;
		./configure;

		msg "Compile LXCfs";
		make -j12;

		msg "Install LXCfs";
		sudo make install;

		sudo systemctl daemon-reload;
		sudo systemctl start lxcfs;
		sudo systemctl start lxd;
	else
		msg "Nothing to do";
	fi

	cd ${GOPATH};

}

build_lxcfs()
{

#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=update-LXCfs
echo "                 _       _                 ____  __  ___  __      ";
echo " _   _ _ __   __| | __ _| |_ ___          / /\ \/ / / __\/ _|___  ";
echo "| | | | '_ \ / _\` |/ _\` | __/ _ \  _____ / /  \  / / /  | |_/ __| ";
echo "| |_| | |_) | (_| | (_| | ||  __/ |_____/ /___/  \/ /___|  _\__ \ ";
echo " \__,_| .__/ \__,_|\__,_|\__\___|       \____/_/\_\____/|_| |___/ ";
echo "      |_|                                                         ";

RESET='\033[0m';
COLOR='\033[1;32m';

REBUILD=0

if [[ "$#" -gt 0 ]];then
	if [[ "$1" == "rebuild" ]];then
		REBUILD="$1"
	fi
fi

if [[ ! -e "${GOPATH}/lxcfs" ]];then

	sudo apt install -qy acl autoconf automake autotools-dev build-essential dnsmasq-base git golang libacl1-dev libcap-dev libtool libuv1-dev m4 make pkg-config rsync squashfs-tools tar tcl xz-utils ebtables libsqlite3-dev
	sudo apt install -qy fuse libfuse-dev libpam0g-dev docbook pkg-config
	
	cd ${GOPATH}
	git clone https://github.com/lxc/lxcfs.git

	REBUILD="setup"
	do_build_lxcfs;

else
	do_build_lxcfs;
fi
}