ksy_compiler = kaitai-struct-compiler

build_dir = build
src_dir = src
test_dir = tests
dist_dir = dist

dist_archive = kaitai_mqtt5_fmt.tar.gz

macro_processor_files = $(src_dir)/m5.rb
macro_processor = $(src_dir)/m5.rb
src_ksy_files = $(src_dir)/mqtt5.ksy.in
generated_ksy_files = $(build_dir)/mqtt5.ksy $(build_dir)/mqtt5_lenient.ksy
distributed_ksy_files = $(dist_dir)/mqtt5.ksy $(dist_dir)/mqtt5_lenient.ksy
generated_ruby_parser_files = $(build_dir)/mqtt5.rb
test_files = $(test_dir)/test.rb
ksy_common_build_deps = $(src_ksy_files) $(macro_processor_files)

# Rules to generate target .ksy files from template
ksy: $(generated_ksy_files)

$(build_dir)/mqtt5.ksy: $(ksy_common_build_deps)
	cat $< | $(macro_processor) > $@

$(build_dir)/mqtt5_lenient.ksy: $(ksy_common_build_deps)
	cat $< | $(macro_processor) -DLENIENT > $@

# Rules to build all the tests
tests: $(generated_ruby_parser_files) $(test_files)

$(build_dir)/mqtt5.rb: $(generated_ksy_files)
	$(ksy_compiler) --outdir $(build_dir) -t ruby $(build_dir)/mqtt5.ksy

# Rules to generate dist file
$(dist_dir)/%.ksy: $(build_dir)/%.ksy
	mkdir -p $(dist_dir)
	cp $< $@

$(dist_archive): $(distributed_ksy_files)
	tar -C $(shell pwd)/$(dist_dir) -zcf $(dist_archive) .

dist: $(dist_archive)

all: ksy tests dist

clean:
	rm -f $(generated_ruby_parser_files) $(generated_ksy_files)
	rm -f $(distributed_ksy_files)
	rm -f $(dist_archive)
