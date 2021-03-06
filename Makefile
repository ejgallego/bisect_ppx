.PHONY : build
build :
	jbuilder build --dev

.PHONY : test
test : build
	jbuilder runtest --dev --no-buffer -j 1

.PHONY : clean
clean :
	jbuilder clean
	for TEST in `ls -d test/usage/*` ; \
	do \
		make -wC $$TEST clean ; \
	done

INSTALLED_ENVIRONMENT := \
    OCAMLPATH=`pwd`/_build/install/default/lib \
    PATH=`pwd`/_build/install/default/bin:$$PATH

.PHONY : usage
usage : build
	for TEST in `ls -d test/usage/*` ; \
	do \
		$(INSTALLED_ENVIRONMENT) make -wC $$TEST || exit 2 ; \
	done

.PHONY : performance
performance : build
	jbuilder build --dev test/performance/test_performance.exe
	cd _build/default/test/ && \
	    performance/test_performance.exe -runner sequential

PRESERVE := _build/default/test/_preserve

.PHONY : save-test-output
save-test-output :
	(cd $(PRESERVE) ; find . -name '*.reference.ml') \
	  | xargs -I FILE cp $(PRESERVE)/FILE test/FILE

# Currently unused; awaiting restoration of self-instrumentation.
GH_PAGES := gh-pages

.PHONY : gh-pages
gh-pages:
	false
	ocamlbuild $(OCAMLBUILD_FLAGS) postprocess.byte
	make -C tests coverage
	rm -rf $(GH_PAGES)
	mkdir -p $(GH_PAGES)
	omd README.md | _build/doc/postprocess.byte > $(GH_PAGES)/index.html
	cd $(GH_PAGES) && \
		git init && \
		git remote add github git@github.com:aantron/bisect_ppx.git && \
		mkdir -p coverage && \
		cp -r ../tests/_report/* coverage/ && \
		git add -A && \
		git commit -m 'Bisect_ppx demonstration' && \
		git push -uf github master:gh-pages
