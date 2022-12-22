# Kaitai MQTT5 protocol ![tests](https://github.com/underhood/kaitai_mqtt5_fmt/actions/workflows/run-tests.yaml/badge.svg) ![gpl 3 badge](https://img.shields.io/badge/license-GPL%20v3%2B-31c654.svg?style=flat)

Aims to create MQTT5 protocol parser using [Kaitai](http://kaitai.io/).

## Usage

Use Kaitai compiler (`kaitai-struct-compiler`) to produce parsers for your desired language which you can use in your project.

Use [Kaitai visualizer](https://github.com/kaitai-io/kaitai_struct_visualizer/) `ksv` to analyse MQTT5 packets (for example captured by wireshark) visually in hex editor. Example:
```
ksv data_samples/connect_valid_1 src/mqtt5.ksy
```

For installation of `kaitai-struct-compiler` and `ksv` instructions please follow [Kaitai](http://kaitai.io/) project documentation.

Originally created for purpose of automating tests of `mqtt_websockets` library as a parser which will verify packets assembled by the library are correct.

## Tests

```
make
./run_tests.sh
```

Provided `Makefile` will use `kaitai-struct-compiler` (which must be in the PATH) to generate ruby parser in `build` folder. `tests/test.rb` script is then verifying that the `ksy` protocol definition is correct by running the parser agains known good/malformed MQTT5 packets.

Test is run automatically also by github actions.
