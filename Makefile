# this makefile is to build tests only

tests: build/mqtt5.rb

build/mqtt5.ksy: src/mqtt5._ksy
	cat src/mqtt5._ksy | ruby src/m5.rb > build/mqtt5.ksy

build/mqtt5_lenient.ksy: src/mqtt5._ksy
	cat src/mqtt5._ksy | ruby src/m5.rb -DLENIENT > build/mqtt5_lenient.ksy

build/mqtt5.rb: build/mqtt5.ksy build/mqtt5_lenient.ksy
	kaitai-struct-compiler --outdir build -t ruby build/mqtt5.ksy

clean:
	rm -f build/*.rb
	rm -f build/*.ksy
	rm -rf dist
	rm -f kaitai_mqtt5_fmt.tar.gz

dist/mqtt5.ksy: build/mqtt5.ksy
	mkdir -p dist
	cp build/mqtt5.ksy dist/mqtt5.ksy

dist/mqtt5_lenient.ksy: build/mqtt5_lenient.ksy
	mkdir -p dist
	cp build/mqtt5_lenient.ksy dist/mqtt5_lenient.ksy

kaitai_mqtt5_fmt.tar.gz: dist/mqtt5.ksy dist/mqtt5_lenient.ksy
	tar -C $(shell pwd)/dist -zcvf kaitai_mqtt5_fmt.tar.gz .

dist: kaitai_mqtt5_fmt.tar.gz

all: tests dist
