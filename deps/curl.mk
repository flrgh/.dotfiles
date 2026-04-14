$(INSTALL_CONFIG)/curlrc: scripts/build-curlrc
	mkdir -p $(dir $@)
	./scripts/build-curlrc > $@

$(DEP)/curl: | $(PKG)/os/curl-build-deps

.PHONY: curl
curl: $(DEP)/curl $(INSTALL_CONFIG)/curlrc | .setup
