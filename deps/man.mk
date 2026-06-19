$(eval $(call man_command,fzf,MANOPT='-R' $$(MISE) exec fzf -- fzf --man,fzf))
$(eval $(call man_command,http,http --generate man,http))
$(eval $(call man_command,promtool,$$(MISE) exec promtool -- promtool --help-man,promtool))
$(eval $(call man_command,rg,$$(MISE) exec ripgrep -- rg --generate man,ripgrep))
$(eval $(call man_command,tea,$$(MISE) exec tea -- tea man,tea))
$(eval $(call man_command,xh,$$(MISE) exec xh -- xh --generate man,xh))

$(eval $(call man_file,bat,$$(dir $$(shell $$(MISE) which bat))bat.1,bat))
$(eval $(call man_file,fd,$$(shell $$(MISE) which fd).1,fd))
$(eval $(call man_file,git-cliff,$$(wildcard $$(shell $$(MISE) where git-cliff)/*/man/git-cliff.1),git-cliff))
$(eval $(call man_file,lsd,$$(wildcard $$(shell $$(MISE) where lsd)/*/lsd.1),lsd))
$(eval $(call man_file,usage,$$(shell $$(MISE) where usage)/usage.1,usage))

$(eval $(call man_files,nfpm,$$(shell $$(MISE) where nfpm)/manpages,nfpm))

$(eval $(call man_tree,gh,$$(wildcard $$(shell $$(MISE) where gh)/*/share/man),gh))
$(eval $(call man_tree,node,$$(shell $$(MISE) where node)/share/man,node))
$(eval $(call man_tree,npm,$(INSTALL_LIB)/node_modules/npm/man,node))
$(eval $(call man_tree,python,$$(shell $$(MISE) where python)/share/man,python))
$(eval $(call man_tree,rustup,$$(shell rustc --print sysroot)/share/man,rust-init))

# fetched from upstream: man source isn't shipped with the installed binary
$(eval $(call man_fetch,age,FiloSottile/age,v,copy,doc/age.1 doc/age-keygen.1))
$(eval $(call man_fetch,direnv,direnv/direnv,v,copy,man/direnv.1 man/direnv-stdlib.1 man/direnv-fetchurl.1 man/direnv.toml.1))
$(eval $(call man_fetch,jq,jqlang/jq,jq-,copy,jq.1.prebuilt))
$(eval $(call man_fetch,shellcheck,koalaman/shellcheck,v,pandoc,shellcheck.1.md))
$(eval $(call man_fetch,shfmt,mvdan/sh,v,scdoc,cmd/shfmt/shfmt.1.scd))
$(eval $(call man_fetch,alacritty,alacritty/alacritty,v,scdoc,extra/man/alacritty.1.scd extra/man/alacritty.5.scd extra/man/alacritty-msg.1.scd extra/man/alacritty-bindings.5.scd extra/man/alacritty-escapes.7.scd))

$(INSTALL_MAN)/index.db: $(MAN_TARGETS)
	mkdir -p "$(dir $@)"
	rm -rf "$(INSTALL_MAN)"/cat[0-9]
	mandb --user-db

.PHONY: man
man: $(INSTALL_MAN)/index.db
