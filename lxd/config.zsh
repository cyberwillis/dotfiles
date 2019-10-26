msg() {
  echo -e "${COLOR}$(date): $1${RESET}";
}

update_lxd()
{
    ARG=""

    pushd

    if [[ "$#" -gt 0 ]];then
        ARG="$1"
    fi

    build_liblxc ${ARG};
    build_lxcfs ${ARG};
    build_lxd ${ARG};
    build_juju;

    popd
}