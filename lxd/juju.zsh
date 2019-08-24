do_build_juju()
{
cd ${GOPATH}/src/github.com/juju/juju;

GITLOG_LOCAL=$(git log develop -n 1 --pretty=%H);
git fetch;
GITLOG_REMOTE=$(git log origin/develop -n 1 --pretty=%H);

if [[ "${GITLOG_LOCAL}" != "${GITLOG_REMOTE}" ]];
then
    msg "Update sources Juju";
	git merge FETCH_HEAD;

    msg "Install Juju";
    cd ${GOPATH}/src/github.com/juju/juju
    export JUJU_MAKE_GODEPS=true
    make dep
    make build;
    make install;
else
	msg "Nothing to do";
fi

cd ${GOPATH};
}

build_juju()
{

#http://patorjk.com/software/taag/#p=display&c=echo&f=Ogre&t=Juju%20
echo "                 _       _              __         _        ";
echo " _   _ _ __   __| | __ _| |_ ___        \ \ _   _ (_)_   _  ";
echo "| | | | '_ \ / _\` |/ _\` | __/ _ \_____   \ \ | | || | | | | ";
echo "| |_| | |_) | (_| | (_| | ||  __/_____/\_/ / |_| || | |_| | ";
echo " \__,_| .__/ \__,_|\__,_|\__\___|     \___/ \__,_|/ |\__,_| ";
echo "      |_|                                       |__/        ";

RESET='\033[0m';
COLOR='\033[1;32m';

do_build_juju;
}