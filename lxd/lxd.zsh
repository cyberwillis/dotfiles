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

do_build_lxd(){

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

build_lxd(){

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

        wget https://dl.google.com/go/go1.12.6.linux-amd64.tar.gz -O ${HOME}/go1.12.6.linux-amd64.tar.gz
        sudo tar -xvf ${HOME}/go1.12.6.linux-amd64.tar.gz -C /opt/
        sudo mv /opt/go /opt/go1.12.6
        sudo rm -rf /usr/local/go
        sudo ln -s /opt/go1.12.6 /usr/local/go

        mkdir -p ${HOME}/go
        
        export GOROOT=/usr/local/go
        export GOPATH=${HOME}/go
        export PATH=${GOPATH}/bin:${GOROOT}/bin:${PATH}
    fi

	sudo apt install -qy acl autoconf automake autotools-dev build-essential dnsmasq-base git \
	                         libacl1-dev libcap-dev libtool libuv1-dev m4 make pkg-config rsync \
							 squashfs-tools tar tcl xz-utils ebtables libsqlite3-dev 

	sudo apt purge lxd -qy
	sudo apt-get install -qy tclsh libuv1-dev
	
	#building the LXD
	go get -d -v github.com/lxc/lxd/lxd
	
	REBUILD="setup"
	do_build_lxd;

else
	do_build_lxd;
fi
}
