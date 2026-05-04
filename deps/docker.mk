DOCKER_MAKEFILE := $(lastword $(MAKEFILE_LIST))

DOCKER_BUILDX_TARGET = $(shell $(MISE) where $(MISE_FULL_buildx))/docker-cli-plugin-docker-buildx

$(DEP)/docker-buildx: $(DEP)/buildx $(DOCKER_MAKEFILE)
	mkdir -v -p $(INSTALL_CONFIG)/docker/cli-plugins
	ln -sfv "$(DOCKER_BUILDX_TARGET)" "$(INSTALL_CONFIG)/docker/cli-plugins/docker-buildx"
	$(TOUCH) --reference $< $@

.PHONY: docker
docker: scripts/update-docker-config $(DEP)/docker-buildx | .setup
	./scripts/update-docker-config
