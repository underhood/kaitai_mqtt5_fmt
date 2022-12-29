# Kaitai MQTT5 protocol ![tests](https://github.com/underhood/kaitai_mqtt5_fmt/actions/workflows/run-tests.yaml/badge.svg) ![gpl 3 badge](https://img.shields.io/badge/license-GPL%20v3%2B-31c654.svg?style=flat)

Aims to create MQTT5 protocol parser using [Kaitai](http://kaitai.io/).

## Build

Make sure `kaitai-struct-compiler` is installed and in your `PATH` env. variable. _(Refer to [Kaitai](http://kaitai.io/) documentation for installation instructions)._

To generate the kaitai-struct `ksy` files run:
```
make
```
This will generate 2 files:

1. `build/mqtt5.ksy` - the main `ksy` to be used with strict data validity checks. Use this if you are writing mqtt5 applications.
1. `build/mqtt5_lenient.ksy` - simillar to the former but skips many data validy checks. This is usefull when just exploring data (e.g. using `ksv`) and will accept incorrect data. Useful when debugging damaged packets.

Other useful Makefile targets are:
1. `make ksy` - default same as above
1. `make tests` - will build necessary files to run tests using `./run_tests.sh`
1. `make dist` - will generate archive file with all files meant for distribution in it
1. `make all` - will build all of the above

## Usage

Use Kaitai compiler (`kaitai-struct-compiler`) to produce parsers for your desired language which you can use in your project.

Use [Kaitai visualizer](https://github.com/kaitai-io/kaitai_struct_visualizer/) `ksv` to analyse MQTT5 packets (for example captured by wireshark) visually in hex editor. Example:
```
ksv data_samples/connect_valid_1 build/mqtt5.ksy
```

For installation of `kaitai-struct-compiler` and `ksv` instructions please follow [Kaitai](http://kaitai.io/) project documentation.

Originally created for purpose of automating tests of [`mqtt_websockets`](https://github.com/underhood/mqtt_websockets) library as a parser used to verify packets assembled by the library are correct.

## Tests

```
make tests
./run_tests.sh
```

Provided `Makefile` will use `kaitai-struct-compiler` (which must be in the PATH) to generate ruby parser in `build` folder. `tests/test.rb` script is then verifying that the `ksy` protocol definition is correct by running the parser against known good/malformed MQTT5 packets.

This tests are ran automatically by github actions.
