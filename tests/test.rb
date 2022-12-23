require 'kaitai/struct/struct'

require_relative '../build/mqtt5.rb'

require "test/unit"

class TestMqttVarintParser < Test::Unit::TestCase
  def test_varint_max
    assert_equal(268435455, Mqtt5::MqttVarint.from_file('data_samples/vbi_max_valid').val )
  end
  def test_varint_oversize
    assert_raise(Kaitai::Struct::ValidationExprError) { Mqtt5::MqttVarint.from_file('data_samples/vbi_oversize') }
  end
  def test_varint_bloated
    # tests parser validates [MQTT-1.5.5-1] quoting:
    # "The encoded value MUST use the minimum number of bytes necessary to represent the value"
    assert_raise(Kaitai::Struct::ValidationExprError) { Mqtt5::MqttVarint.from_file('data_samples/vbi_bloated') }
  end
  def test_varint_null
    bytes = "\x00"
    assert_equal(0, Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes)).val)
  end
  def test_varint_limits
    bytes127 = "\x7F"
    varint = Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes127))
    assert_equal(127, varint.val)
    assert_equal(1, varint.bytes.size)

    bytes128 = "\x80\x01"
    varint = Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes128))
    assert_equal(128, varint.val)
    assert_equal(2, varint.bytes.size)

    bytes16383 = "\xFF\x7F"
    assert_equal(16383, Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes16383)).val)
    bytes16384 = "\x80\x80\x01"
    assert_equal(16384, Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes16384)).val)
    bytes2097151 = "\xFF\xFF\x7F"
    assert_equal(2097151, Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes2097151)).val)
    bytes2097152 = "\x80\x80\x80\x01"
    assert_equal(2097152, Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes2097152)).val)
    bytes268435455 = "\xFF\xFF\xFF\x7F"
    assert_equal(268435455, Mqtt5::MqttVarint.new(Kaitai::Struct::Stream.new(bytes268435455)).val)
  end
end

class TestMqttPingParsers < Test::Unit::TestCase
  def test_ping_parse
    ping_with_len = "\xC0\05" # test ping with non 0 payload len fails to parse
    ping_with_flags = "\xC3\x00" # tests ping with flags set to non0 fails
    ping_no_len = "\xC0" # tests ping without remaining length fails
    ping_valid = "\xC0\00"

    assert_raise( EOFError ) { Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(ping_no_len)) }
    assert_raise( Kaitai::Struct::ValidationExprError ) { Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(ping_with_len)) }
    assert_raise( Kaitai::Struct::ValidationNotEqualError ) { Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(ping_with_flags)) }

    assert_nothing_raised { ping = Mqtt5::MqttMsg.from_file('data_samples/pingreq_valid') }
    ping = Mqtt5::MqttMsg.from_file('data_samples/pingreq_valid')
    assert_equal(ping.mqtt_cpt.cpt, :mqtt_cpt_enum_pingreq)
  end
  def test_pingresp_parse
    pingresp_with_len = "\xD0\05" # test ping with non 0 payload len fails to parse
    pingresp_with_flags = "\xD3\x00" # tests ping with flags set to non0 fails
    pingresp_no_len = "\xD0" # tests ping without remaining length fails
    pingresp_valid = "\xD0\00"
    ping_valid = "\xC0\00"

    assert_raise( EOFError ) { Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(pingresp_no_len)) }
    assert_raise( Kaitai::Struct::ValidationExprError ) { Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(pingresp_with_len)) }
    assert_raise( Kaitai::Struct::ValidationNotEqualError ) { Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(pingresp_with_flags)) }

    assert_nothing_raised { pingresp = Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(pingresp_valid)) }
    pingresp = Mqtt5::MqttMsg.new(Kaitai::Struct::Stream.new(pingresp_valid))
    assert_equal(pingresp.mqtt_cpt.cpt, :mqtt_cpt_enum_pingresp)
    assert_raise( Kaitai::Struct::ValidationNotEqualError ) { Mqtt5::MqttPingresp.new(Kaitai::Struct::Stream.new(ping_valid)) }
  end
end

class TestMqttConnectParser < Test::Unit::TestCase
  def test_ConnectParser1
    assert_nothing_raised {
      connect = Mqtt5::MqttMsg.from_file('data_samples/connect_minimal')
      assert_equal(:mqtt_cpt_enum_connect, connect.mqtt_cpt.cpt)
    }

    connect = Mqtt5::MqttConnect.from_file('data_samples/connect_minimal')
    assert_equal(:mqtt_cpt_enum_connect, connect.fixed_hdr.cpt)
    assert_equal(5, connect.body.var_hdr.protocol_version)
    assert_equal("\x00\x03MQTT", connect.body.var_hdr.protocol_name)

    connect = Mqtt5::MqttConnect.from_file('data_samples/connect_valid_1')
    assert_equal(:mqtt_cpt_enum_connect, connect.fixed_hdr.cpt)
    assert_equal(connect.body.var_hdr.protocol_version, 5)
    assert_equal("\x00\x03MQTT", connect.body.var_hdr.protocol_name)
    assert_equal(5, connect.body.var_hdr.keep_alive)

    assert_equal(3, connect.body.payload.user_name.len_str)
    assert_equal("usr", connect.body.payload.user_name.str)
    assert_equal(3, connect.body.payload.password.len_data)
    assert_equal("pwd", connect.body.payload.password.data)

    assert_equal(4, connect.body.payload.client_id.len_str)
    assert_equal("test", connect.body.payload.client_id.str)

    assert_equal(10, connect.body.payload.will_data.will_topic.len_str)
    assert_equal("will_topic", connect.body.payload.will_data.will_topic.str)
    assert_equal(12, connect.body.payload.will_data.will_payload.len_data)
    assert_equal("will_payload", connect.body.payload.will_data.will_payload.data)
    

    assert_raise(Kaitai::Struct::ValidationGreaterThanError) {
      # will flag set but will qos == 3
      connect = Mqtt5::MqttConnect.from_file('data_samples/connect_qos_violate')
    }
    assert_raise(Kaitai::Struct::ValidationExprError) {
      # will flag not set but will qos != 0
      connect = Mqtt5::MqttConnect.from_file('data_samples/connect_qos_violate2')
    }
    assert_raise(EOFError) {
      # remaining length of fixed header too long data not present
      connect = Mqtt5::MqttConnect.from_file('data_samples/connect_remlength_toobig')
    }
    assert_raise(Kaitai::Struct::ValidationExprError) {
      # remaining length of fixed header too long data present after the packet
      connect = Mqtt5::MqttConnect.from_file('data_samples/connect_remlength_toobig_data_present')
    }
  end
end
