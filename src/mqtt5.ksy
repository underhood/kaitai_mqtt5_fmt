meta:
  id: mqtt5
  file-extension: bin
  bit-endian: be
  endian: be

seq:
  - id: mqtt_message
    type: mqtt_msg

enums:
# [MQTT-2.1.2]
  mqtt_cpt_enum:
    1: connect
    2: connack
    3: publish
    4: puback
    5: pubrec
    6: pubrel
    7: pubcomp
    8: subscribe
    9: suback
    10: unsubscribe
    11: unsuback
    12: pingreq
    13: pingresp
    14: disconnect
    15: auth

types:
  mqtt_cpt:
    seq:
      - id: cpt
        type: b4
        enum: mqtt_cpt_enum

  mqtt_msg:
    seq:
      - id: message
        type:
          switch-on: 'mqtt_cpt.cpt'
          cases:
            mqtt_cpt_enum::pingreq: mqtt_pingreq
            mqtt_cpt_enum::pingresp: mqtt_pingresp
            mqtt_cpt_enum::connect: mqtt_connect
    instances:
      # I do this because first 4 bits are signifying packet type and second 4 bits are packet type dependent
      # when I try to do sth. like:
      # seq:
      #   - id: cpt
      #     type: b4
      #   - id: flags
      #     type:
      #       switch-on: 'cpt'
      #       cases:
      #         ...
      # the parser chosen in the switch-on will start parsing from the second byte
      mqtt_cpt:
        type: mqtt_cpt
        pos: 0
        size: 1

  mqtt_pingreq:
    seq:
      - id: cpt
        type: b4
        valid:
          expr: '_ == 0xC' # for some reason cannot use contents with b4 type
      - id: reserved
        type: b4
        valid:
          expr: '_ == 0'
      - id: rem_length
        type: mqtt_varint
        valid:
          expr: '_.val == 0'
  mqtt_pingresp:
    seq:
     - id: cpt
       type: b4
       valid:
         expr: '_ == 0xD' # for some reason cannot use contents with b4 type
     - id: reserved
       type: b4
       valid:
         expr: '_ == 0'
     - id: rem_length
       type: mqtt_varint
       valid:
         expr: '_.val == 0'

# MQTT Connect
  connect_flags:
    seq:
      - id: user_name
        type: b1
      - id: password
        type: b1
      - id: will_retain
        type: b1
      - id: will_qos
        type: b2
        valid:
          expr: '_ <= 2'
      - id: will
        type: b1
      - id: clean_start
        type: b1
      - id: reserved
        type: b1
        valid:
          expr: '_ == false'
  mqtt_connect_variable_hdr:
    seq:
      - id: protocol_name
        contents: [ 0x00, 0x03, M, Q, T, T ]
      - id: protocol_version
        contents: [ 0x05 ]
      - id: connect_flags
        type: connect_flags
      - id: keep_alive
        type: u2
      - id: properties_len
        type: mqtt_varint
      - id: properties
        type: mqtt_properties
        size: properties_len.val
        valid:
          expr: '_._io.eof'
  mqtt_will_data:
    seq:
      - id: will_prop_len
        type: mqtt_varint
      - id: will_props
        type: mqtt_properties
        size: will_prop_len.val
        if: will_prop_len.val > 0
        valid:
          expr: '_._io.eof'
      - id: will_topic
        type: mqtt_utf8_string
      - id: will_payload
        type: mqtt_bin_data
  mqtt_connect_payload:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901058 [MQTT-3.1.3]
    seq:
      - id: client_id
        type: mqtt_utf8_string
      - id: will_data
        type: mqtt_will_data
        if: _parent.var_hdr.connect_flags.will
      - id: user_name
        type: mqtt_utf8_string
        if: _parent.var_hdr.connect_flags.user_name
      - id: password
        type: mqtt_bin_data
        if: _parent.var_hdr.connect_flags.password
  mqtt_connect_fixed_hdr:
    seq:
      - id: cpt
        type: b4
        valid:
          expr: '_ == mqtt_cpt_enum::connect'
        enum: mqtt_cpt_enum
      - id: reserved
        type: b4
        valid:
          expr: '_ == 0'
      - id: rem_length
        type: mqtt_varint
        valid:
          expr: '_.val != 0'
  mqtt_connect_body:
    seq:
      - id: var_hdr
        type: mqtt_connect_variable_hdr
      - id: payload
        type: mqtt_connect_payload
  mqtt_connect:
    seq:
      - id: fixed_hdr
        type: mqtt_connect_fixed_hdr
      - id: body
        type: mqtt_connect_body
        size: fixed_hdr.rem_length.val
        valid:
          expr: '_._io.eof'

  mqtt_property:
    seq:
      - id: id
        type: u1
      - id: val
        type:
          switch-on: id
          cases:
            0x22: u2
  mqtt_properties:
    seq:
      - id: properties
        type: mqtt_property
        repeat: eos

# Basic MQTT Datatypes
  mqtt_bin_data:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901012 [MQTT-1.5.6]
    -orig-id: Binary Data
    seq:
      - id: len_data
        type: u2
      - id: data
        size: len_data
  mqtt_utf8_string:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901010 [MQTT-1.5.4]
    -orig-id: UTF-8 Encoded String
    seq:
      - id: len_str
        type: u2
      - id: str
        type: str
        size: len_str
        encoding: UTF-8
  mqtt_varint:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901011 [MQTT-1.5.5]
    -orig-id: Variable Byte Integer
    seq:
      - id: bytes
        type: u1
        repeat: until
        repeat-until: '(_ & (1 << 7)) == 0'
        valid:
# MQTT spec allows max 4 bytes even though unlimited is teoretically possible
          expr: '(bytes.size <= 4)
          and (val <= 127 ? bytes.size == 1 :
            (val <= 16383 ? bytes.size == 2 :
              (val <= 2097151 ? bytes.size == 3 : bytes.size == 4)))'
    instances:
      val:
        value: '(bytes[0] & 0x7F)
        + (bytes.size > 1 ? (bytes[1] & 0x7F) * (1 << 7) : 0)
        + (bytes.size > 2 ? (bytes[2] & 0x7F) * (1 << 14) : 0)
        + (bytes.size > 3 ? (bytes[3] & 0x7F) * (1 << 21) : 0)'
