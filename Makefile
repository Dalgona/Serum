serum:
	mix deps.get
	MIX_ENV=prod mix escript.build

install: serum
	install -m755 serum /usr/local/bin

uninstall:
	rm -f /usr/local/bin/serum

clean:
	rm -f serum
	rm -rf _build
	rm -rf deps
