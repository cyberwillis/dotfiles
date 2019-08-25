alias lxclist='lxc ls --format=csv'
lxcstart()
{
    if [[ -n "${1}" ]]; then
        _MACHINE_CONTAINER_=${1}
        if [[ "$(lxc ls ${_MACHINE_CONTAINER_} --format=csv 2> /dev/null)" != "" ]]; then
            _TMP_=$(lxc ls ${_MACHINE_CONTAINER_} --format=csv | cut -d"," -f2 2> /dev/null)
            if [[ "${_TMP_}" == "RUNNING" ]]; then
                lxc console "${_MACHINE_CONTAINER_}"
            elif [[ "${_TMP_}" == "STOPPED" ]]; then
                lxc start "${_MACHINE_CONTAINER_}" && lxc console "${_MACHINE_CONTAINER_}"
            fi
        else
            echo "Container not found"
        fi
    fi
}

lxcexec()
{
    if [[ -n "${1}" ]]; then
        _MACHINE_CONTAINER_=${1}
        if [[ "$(lxc ls ${_MACHINE_CONTAINER_} --format=csv 2> /dev/null)" != "" ]]; then
            _TMP_=$(lxc ls ${_MACHINE_CONTAINER_} --format=csv | cut -d"," -f2 2> /dev/null)
            if [[ "${_TMP_}" == "RUNNING" ]]; then
                lxc exec "${_MACHINE_CONTAINER_}" -- su ubuntu
            elif [[ "${_TMP_}" == "STOPPED" ]]; then
                lxc start "${_MACHINE_CONTAINER_}" && lxc exec "${_MACHINE_CONTAINER_}" -- su ubuntue
            fi
        else
            echo "Container not found"
        fi
    fi
}

lxcstop()
{
    if [[ -n "${1}" ]]; then
        _MACHINE_CONTAINER_=${1}
        if [[ "$(lxc ls ${_MACHINE_CONTAINER_} --format=csv 2> /dev/null)" != "" ]]; then
            _TMP_=$(lxc ls ${_MACHINE_CONTAINER_} --format=csv | cut -d"," -f2 2> /dev/null)
            if [[ "${_TMP_}" == "RUNNING" ]]; then
                lxc stop -f "${_MACHINE_CONTAINER_}"
            elif [[ "${_TMP_}" == "STOPPED" ]]; then
                echo "Container already stopped"
            fi
        else
            echo "Container not found"
        fi
    fi
}

lxccommit()
{
    pushd ${GOPATH}/src/github.com/lxc/lxd;

    git checkout master

    git log --oneline -n 5 --format="%C(auto)%h %Cgreen[%an] %Creset- %s"
    #git log --oneline -n 5 --format="%C(auto)%h %Cgreen[%an]  %Cred[%cd] %Creset- %s"

    popd
}