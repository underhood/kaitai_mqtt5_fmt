# this makefile is to build tests only

build/mqtt5.rb: src/mqtt5.ksy
	kaitai-struct-compiler --outdir build -t ruby src/mqtt5.ksy

clean:
	rm -f build/mqtt5.rb
