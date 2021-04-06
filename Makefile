# A lot of this Makefile right now is temporary since we have a private
# repo so that we can more sanely create
ASSETFS_PATH?=internal/server/gen/bindata_ui.go

GIT_COMMIT=$$(git rev-parse --short HEAD)
GIT_DIRTY=$$(test -n "`git status --porcelain`" && echo "+CHANGES" || true)
GIT_DESCRIBE=$$(git describe --tags --always --match "v*")
GIT_IMPORT="github.com/hashicorp/vagrant/internal/version"
GOLDFLAGS="-X $(GIT_IMPORT).GitCommit=$(GIT_COMMIT)$(GIT_DIRTY) -X $(GIT_IMPORT).GitDescribe=$(GIT_DESCRIBE)"
CGO_ENABLED?=0

.PHONY: bin
bin: # bin creates the binaries for Vagrant for the current platform
	CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -tags assetsembedded -o ./vagrant ./cmd/vagrant

.PHONY: bin/windows
bin/windows: # create windows binaries
	GOOS=linux GOARCH=amd64 go build -o ./internal/assets/ceb/ceb ./cmd/vagrant-entrypoint
	cd internal/assets && go-bindata -pkg assets -o prod.go -tags assetsembedded ./ceb
	GOOS=windows GOARCH=amd64 CGO_ENABLED=$(CGO_ENABLED) go build -ldflags $(GOLDFLAGS) -tags assetsembedded -o ./vagrant.exe ./cmd/vagrant

.PHONY: bin/linux
bin/linux: # create Linux binaries
	GOOS=linux GOARCH=amd64 $(MAKE) bin

.PHONY: bin/darwin
bin/darwin: # create Darwin binaries
	GOOS=darwin GOARCH=amd64 $(MAKE) bin

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
		-I=./vendor/proto/api-common-protos/ \
		--doc_out=./doc --doc_opt=html,index.html \
		./internal/server/proto/server.proto
