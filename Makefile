ASSETFS_PATH?=internal/server/gen/bindata_ui.go

GIT_COMMIT=$$(git rev-parse --short HEAD)
GIT_DIRTY=$$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)
GIT_DESCRIBE=$$(git describe --tags --always --match "v*")
GIT_IMPORT="github.com/hashicorp/vagrant/internal/version"
GOLDFLAGS="-X $(GIT_IMPORT).GitCommit=$(GIT_COMMIT)$(GIT_DIRTY) -X $(GIT_IMPORT).GitDescribe=$(GIT_DESCRIBE)"
CGO_ENABLED?=0

.PHONY: bin
bin: # bin creates the binaries for Vagrant for the current platform
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/vagrant-go ./cmd/vagrant

.PHONY: debug
debug: # debug creates an executable with optimizations off, suitable for debugger attachment
	GCFLAGS="all=-N -l" $(MAKE) bin

.PHONY: all
all:
	$(MAKE) bin/windows
	$(MAKE) bin/linux
	$(MAKE) bin/darwin

.PHONY: bin/windows
bin/windows:
	$(MAKE) bin/windows-amd64
	$(MAKE) bin/windows-386

.PHONY: bin/windows-amd64
bin/windows-amd64: # create windows binaries
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=windows GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -tags assetsembedded -o ./bin/vagrant-go_windows_amd64.exe ./cmd/vagrant

.PHONY: bin/windows-386
bin/windows-386: # create windows binaries
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=windows GOARCH=386 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -tags assetsembedded -o ./bin/vagrant-go_windows_386.exe ./cmd/vagrant

.PHONY: bin/linux
bin/linux:
	$(MAKE) bin/linux-amd64
	$(MAKE) bin/linux-386

.PHONY: bin/linux-amd64
bin/linux-amd64: # create Linux binaries
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=linux GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/vagrant-go_linux_amd64 ./cmd/vagrant

.PHONY: bin/linux-386
bin/linux-386: # create Linux binaries
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=linux GOARCH=386 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/vagrant-go_linux_386 ./cmd/vagrant

.PHONY: bin/darwin
bin/darwin:
	$(MAKE) bin/darwin-amd64
	$(MAKE) bin/darwin-arm64
	$(MAKE) bin/darwin-universal

.PHONY: bin/darwin-amd64
bin/darwin-amd64: # create Darwin binaries
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/vagrant-go_darwin_amd64 ./cmd/vagrant

.PHONY: bin/darwin-arm64
bin/darwin-arm64: # create Darwin binaries
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/vagrant-go_darwin_arm64 ./cmd/vagrant

.PHONY: bin/darwin-universal
bin/darwin-universal:
	@test -s "thirdparty/proto/api-common-protos/.git" || { echo "git submodules not initialized, run 'git submodule update --init --recursive' and try again"; exit 1; }
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/.vagrant-go_darwin_arm64 ./cmd/vagrant
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -gcflags="$(GCFLAGS)" -tags assetsembedded -o ./bin/.vagrant-go_darwin_amd64 ./cmd/vagrant
	go run github.com/randall77/makefat ./bin/vagrant-go_darwin_universal ./bin/.vagrant-go_darwin_arm64 ./bin/.vagrant-go_darwin_amd64
	rm -f ./bin/.vagrant-go_darwin*

.PHONY: clean
clean:
	rm -f ./bin/vagrant-go* ./bin/.vagrant-go_darwin*

.PHONY: test
test: # run tests
	go test ./...

.PHONY: format
format: # format go code
	gofmt -s -w ./

.PHONY: docker/mitchellh
docker/mitchellh:
	DOCKER_BUILDKIT=1 docker build \
					--ssh default \
					--secret id=ssh.config,src="${HOME}/.ssh/config" \
					--secret id=ssh.key,src="${HOME}/.ssh/config" \
					-t vagrant:latest \
					.

# This currently assumes you have run `ember build` in the ui/ directory
static-assets:
	@go-bindata -pkg gen -prefix dist -o $(ASSETFS_PATH) ./ui/dist/...
	@gofmt -s -w $(ASSETFS_PATH)

.PHONY: gen/doc
gen/doc:
	@rm -rf ./doc/* 2> /dev/null
	protoc -I=. \
		-I=./thirdparty/proto/api-common-protos/ \
		--doc_out=./doc --doc_opt=html,index.html \
		./internal/server/proto/server.proto
