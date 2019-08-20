export CGO_CFLAGS="-I${GOPATH}/deps/sqlite/ -I${GOPATH}/deps/libco/ -I${GOPATH}/deps/raft/include/ -I${GOPATH}/deps/dqlite/include/"
export CGO_LDFLAGS="-L${GOPATH}/deps/sqlite/.libs/ -L${GOPATH}/deps/libco/ -L${GOPATH}/deps/raft/.libs -L${GOPATH}/deps/dqlite/.libs/"
export LD_LIBRARY_PATH="${GOPATH}/deps/sqlite/.libs/:${GOPATH}/deps/libco/:${GOPATH}/deps/raft/.libs/:${GOPATH}/deps/dqlite/.libs/"

#export CGO_CFLAGS="-I/media/willismar/Dados/go/deps/sqlite/ -I/media/willismar/Dados/go/deps/libco/ -I/media/willismar/Dados/go/deps/raft/include/ -I/media/willismar/Dados/go/deps/dqlite/include/"
#export CGO_LDFLAGS="-L/media/willismar/Dados/go/deps/sqlite/.libs/ -L/media/willismar/Dados/go/deps/libco/ -L/media/willismar/Dados/go/deps/raft/.libs -L/media/willismar/Dados/go/deps/dqlite/.libs/"
#export LD_LIBRARY_PATH="/media/willismar/Dados/go/deps/sqlite/.libs/:/media/willismar/Dados/go/deps/libco/:/media/willismar/Dados/go/deps/raft/.libs/:/media/willismar/Dados/go/deps/dqlite/.libs/"
