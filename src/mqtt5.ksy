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
            mqtt_cpt_enum::connack: mqtt_connack
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
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901195 [MQTT-3.12]
    -orig-id: PINGREQ – PING request
    seq:
      - id: cpt
        type: b4
        valid:
          eq: 0xC
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901196 [MQTT-3.12.1]
        -orig-id: PINGREQ Fixed Header
      - id: reserved
        type: b4
        valid:
          eq: 0
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901196 [MQTT-3.12.1]
        -orig-id: PINGREQ Fixed Header
      - id: rem_length
        type: mqtt_varint
        valid:
          expr: '_.val == 0'
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901196 [MQTT-3.12.1]
        -orig-id: PINGREQ Fixed Header
  mqtt_pingresp:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901200 [MQTT-3.13]
    -orig-id: PINGRESP – PING response
    seq:
      - id: cpt
        type: b4
        valid:
          eq: 0xD
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901201 [MQTT-3.13.1]
        -orig-id: PINGRESP Fixed Header
      - id: reserved
        type: b4
        valid:
          eq: 0
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901201 [MQTT-3.13.1]
        -orig-id: PINGRESP Fixed Header
      - id: rem_length
        type: mqtt_varint
        valid:
          expr: '_.val == 0'
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901201 [MQTT-3.13.1]
        -orig-id: PINGRESP Fixed Header

# MQTT Connect
  connect_flags:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901038 [MQTT-3.1.2.3]
    -orig-id: Connect Flags
    seq:
      - id: user_name
        type: b1
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901043 [MQTT-3.1.2.8]
        -orig-id: User Name Flag
      - id: password
        type: b1
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901044 [MQTT-3.1.2.9]
        -orig-id: Password Flag
      - id: will_retain
        type: b1
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901042 [MQTT-3.1.2.7]
        -orig-id: Will Retain
      - id: will_qos
        type: b2
        valid:
          max: 2
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901041 [MQTT-3.1.2.6]
        -orig-id: Will QoS
      - id: will
        type: b1
        valid:
          expr: '_ or (_ == false and will_qos == 0)'
#          -expr-ref: [MQTT-3.1.2-11] and [MQTT-3.1.2-12]
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901040 [MQTT-3.1.2.5]
        -orig-id: Will Flag
      - id: clean_start
        type: b1
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901039 [MQTT-3.1.2.4]
        -orig-id: Clean Start
      - id: reserved
        type: b1
        valid:
          eq: false
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901038 [MQTT-2.1.2-3]
        -orig-id: Reserved
  mqtt_connect_variable_hdr:
    seq:
      - id: protocol_name
        contents: [ 0x00, 0x03, M, Q, T, T ]
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901036 [MQTT-3.1.2.1]
        -orig-id: Protocol Name
      - id: protocol_version
        type: u1
        valid:
          eq: 0x05
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901037 [MQTT-3.1.2.2]
        -orig-id: Protocol Version
      - id: connect_flags
        type: connect_flags
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901038 [MQTT-3.1.2.3]
        -orig-id: Connect Flags
      - id: keep_alive
        type: u2
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901045 [MQTT-3.1.2.10]
        -orig-id: Keep Alive
      - id: properties_len
        type: mqtt_varint
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901047 [MQTT-3.1.2.11.1]
        -orig-id: Property Length
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
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901069 [MQTT-3.1.3.3]
        -orig-id: Will Topic
      - id: will_payload
        type: mqtt_bin_data
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901070 [MQTT-3.1.3.4]
        -orig-id: Will Payload
  mqtt_connect_payload:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901058 [MQTT-3.1.3]
    -orig-id: Connect Payload
    seq:
      - id: client_id
        type: mqtt_utf8_string
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901059 [MQTT-3.1.3.1]
        -orig-id: Client Identifier (ClientID)
      - id: will_data
        type: mqtt_will_data
        if: _parent.var_hdr.connect_flags.will
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901060 [MQTT-3.1.3.2]
        -orig-id: Will Properties
      - id: user_name
        type: mqtt_utf8_string
        if: _parent.var_hdr.connect_flags.user_name
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901071 [MQTT-3.1.3.5]
        -orig-id: User Name
      - id: password
        type: mqtt_bin_data
        if: _parent.var_hdr.connect_flags.password
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901072 [MQTT-3.1.3.6]
        -orig-id: Password
  mqtt_connect_fixed_hdr:
    seq:
      - id: cpt
        type: b4
        valid:
          eq: mqtt_cpt_enum::connect
        enum: mqtt_cpt_enum
      - id: reserved
        type: b4
        valid:
          eq: 0
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

  mqtt_connack_fixed_hdr:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901075 [MQTT-3.2.1]
    -orig-id: CONNACK Fixed Header
    seq:
      - id: cpt
        type: b4
        valid:
          eq: 0x2
      - id: reserved
        type: b4
        valid:
          eq: 0
      - id: rem_length
        type: mqtt_varint
  mqtt_connack_body:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901076 [MQTT-3.2.2]
    -orig-id: CONNACK Variable Header
    seq:
      - id: reserved
        type: b7
        valid:
          eq: 0
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901077 [MQTT-3.2.2.1]
        -orig-id: Connect Acknowledge Flags
      - id: session_present
        type: b1
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901078 [MQTT-3.2.2.1.1]
        -orig-id: Session Present
      - id: reason_code
        type: u1
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901079 [MQTT-3.2.2.2]
        -orig-id: Connect Reason Code
      - id: property_len
        type: mqtt_varint
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901081 [MQTT-3.2.2.3.1]
        -orig-id: Property Length
      - id: properties
        type: mqtt_properties
        size: property_len.val
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901080 [MQTT-3.2.2.3]
        -orig-id: CONNACK Properties
  mqtt_connack:
    doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901074 [MQTT-3.2]
    -orig-id: CONNACK – Connect acknowledgement
    seq:
      - id: fixed_hdr
        type: mqtt_connack_fixed_hdr
        doc-ref: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901075 [MQTT-3.2.1]
        -orig-id: CONNACK Fixed Header
      - id: body
        type: mqtt_connack_body
        size: fixed_hdr.rem_length.val

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
