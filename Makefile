GZIP ?= gzip --fast
INSTALL ?= install

TARGETS := build/container-api.tar

.PHONY: all clean openapi testing/behavior/api.test

all: build/release.tar.gz

clean:
	$(RM) -r build
	$(MAKE) -C "openapi" clean
	$(MAKE) -C "terraform" clean

build:
	mkdir -p "build"

openapi:
	$(MAKE) -C "openapi" ../backend/cmd/api/models
	$(MAKE) -C "openapi" ../backend/cmd/api/openapi/docs

build/container-%.tar: | openapi build
	DOCKER_BUILDKIT=1 docker build . \
		--quiet \
		--file "backend/cmd/$*/Dockerfile" \
		--tag "$*"

	docker save --output "$@" "$*"

terraform/%:
	$(MAKE) -C "terraform" $^

build/build.tar.gz: $(TARGETS)
		tar -cf "$@" \
			--use-compress-program="$(GZIP)" \
			$^

build/release.tar.gz: terraform/terraform.tar.gz build/build.tar.gz
	cat $^ > "$@"

testing/behavior/api.test:
	cd testing/behavior && go test -o api.test -c .

build/testing: testing/behavior/api.test
	$(INSTALL) -d $@
	mv $< $@/api.test
	cp -r testing/behavior/features build/testing/features
