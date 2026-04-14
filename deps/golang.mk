.PHONY: golang
golang: private DIRS = \
	$(INSTALL_PREFIX)/go \
	$(INSTALL_PATH)/go \
	$(INSTALL_CONFIG)/go/telemetry/local \
	$(INSTALL_CONFIG)/go/telemetry/upload
golang: private GO = $(MISE) exec go -- go
golang: $(DEP)/gopls $(DEP)/gotags .WAIT $(MISE_SHIMS) | .setup
	$(GO) telemetry off
	which gopls || ineed install --reinstall gopls
	which gotags || ineed install --reinstall gotags
	for dir in $(DIRS); do \
		[[ -d $$dir ]] || continue; \
		chmod -R u+w "$$dir"; \
		rm -rf "$$dir"; \
	done
