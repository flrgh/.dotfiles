$(INSTALL_CONFIG)/curlrc: scripts/build-curlrc
	mkdir -p $(dir $@)
	./scripts/build-curlrc > $@

$(DEP)/curl: $(DEP)/nghttp3 | $(PKG)/os/curl-build-deps

.PHONY: curl
curl: $(DEP)/curl $(INSTALL_CONFIG)/curlrc | .setup
