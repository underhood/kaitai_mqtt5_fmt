# this makefile is to build tests only

mqtt5.rb: mqtt5.ksy
	kaitai-struct-compiler -t ruby mqtt5.ksy

clean:
	rm -f mqtt5.rb
