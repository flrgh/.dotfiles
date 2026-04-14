$(PKG)/python.cleanup: $(DEP)/python | $(MISE)
	$(SCRIPT)/python-cleanup
	$(TOUCH) --reference "$<" "$@"

$(PKG)/python: $(DEP)/python | $(PKG)/python.cleanup $(MISE)
	$(TOUCH) --reference "$<" "$@"
