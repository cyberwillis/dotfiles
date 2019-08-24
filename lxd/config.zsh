msg() {
  echo -e "${COLOR}$(date): $1${RESET}";
}

update_lxd()
{
    ARG=""

    if [[ "$#" -gt 0 ]];then
        ARG="$1"
    fi

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

    build_liblxc ${ARG};
    build_lxcfs ${ARG};
    build_lxd ${ARG};
    build_juju;
}