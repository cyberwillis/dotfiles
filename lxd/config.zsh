msg() {
  echo -e "${COLOR}$(date): $1${RESET}";
}

update_lxd()
{
    ARG=""

    pushd

    if [[ "$#" -gt 0 ]]; then
		DATE_="$1"
		echo "Working on date: ${DATE_}"
	fi

	do_install_go ;
	do_install_python_packages;
	do_install_fs;
	do_build_criu ${DATE_};
	do_install_tools ;
	do_build_libco ${DATE_};
	do_build_raft; #didnt put date here because old commits have problems
	do_build_sqlite ${DATE_};
	do_build_dqlite ${DATE_};
	do_build_libseccomp; #dont need old commits
	do_build_libnvidia_container ${DATE_};
	do_build_lxc ${DATE_};
	do_build_lxcfs ${DATE_};
	do_build_lxd ${DATE_};

    popd
}

update_lxd1()
{
    ARG=""

    pushd

    if [[ "$#" -gt 0 ]];then
        ARG="$1"
    fi

    build_liblxc ${ARG};
    build_lxcfs ${ARG};
    build_lxd_old ${ARG};
    build_juju;

	popd
}