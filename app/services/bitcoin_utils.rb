# frozen_string_literal: true

require "ecdsa"
require "digest"

module BitcoinUtils
  extend self

  BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".freeze
  BASE58_INDEX = BASE58_ALPHABET.each_char.with_index.to_h.freeze
  GROUP = ECDSA::Group::Secp256k1
  MAINNET_PRIVATE_PREFIX = 0x80
  MAINNET_P2PKH_PREFIX = 0x00

  def valid_private_key_hex?(hex)
    normalized = normalize_private_key_hex(hex)
    return false unless normalized

    value = normalized.to_i(16)
    value.positive? && value < GROUP.order
  end

  def valid_public_key_hex?(hex)
    decode_public_key_point(hex)
    true
  rescue ArgumentError
    false
  end

  def derive_from_private(priv_hex)
    normalized = normalize_private_key_hex(priv_hex)
    raise ArgumentError, "Invalid private key" unless normalized

    value = normalized.to_i(16)
    raise ArgumentError, "Invalid private key" unless value.positive? && value < GROUP.order

    point = GROUP.generator.multiply_by_scalar(value)
    compressed_bytes = encode_point(point, compression: true)
    uncompressed_bytes = encode_point(point, compression: false)

    {
      private_key_hex: normalized,
      public_key_compressed: bytes_to_hex(compressed_bytes),
      public_key_uncompressed: bytes_to_hex(uncompressed_bytes),
      wif_compressed: encode_wif(normalized, compressed: true),
      wif_uncompressed: encode_wif(normalized, compressed: false),
      address_p2pkh_compressed: pubkey_bytes_to_address(compressed_bytes),
      address_p2pkh_uncompressed: pubkey_bytes_to_address(uncompressed_bytes)
    }
  end

  def decode_wif(wif)
    raw = decode_base58(wif)
    raise ArgumentError, "Invalid WIF" unless raw
    raise ArgumentError, "Invalid WIF length" if raw.bytesize < 5

    data = raw[0...-4]
    checksum = raw[-4, 4]
    raise ArgumentError, "Invalid WIF checksum" unless checksum_bytes(data) == checksum

    bytes = data.bytes
    version = bytes.shift
    raise ArgumentError, "Unsupported WIF version" unless version == MAINNET_PRIVATE_PREFIX

    compressed = false
    key_bytes = case bytes.length
                when 32
                  bytes
                when 33
                  raise ArgumentError, "Invalid WIF suffix" unless bytes.last == 0x01
                  compressed = true
                  bytes[0, 32]
                else
                  raise ArgumentError, "Invalid WIF payload"
                end

    [bytes_to_hex(key_bytes.pack("C*")), compressed]
  end

  def public_key_details(hex)
    decoded = decode_public_key_point(hex)
    bytes = decoded[:bytes]

    {
      public_key: bytes_to_hex(bytes),
      hash160: bytes_to_hex(hash160(bytes)),
      address_p2pkh: pubkey_bytes_to_address(bytes)
    }
  end

  def pubkey_hex_to_address(hex)
    pubkey_bytes_to_address(hex_to_bytes(hex))
  end

  private

  def normalize_private_key_hex(hex)
    return unless hex.is_a?(String) && hex.match?(/\A[0-9a-fA-F]{64}\z/)

    hex.downcase
  end

  def decode_public_key_point(hex)
    bytes = hex_to_bytes(hex)
    point = ECDSA::Format::PointOctetString.decode(bytes, GROUP)
    { bytes: bytes, point: point }
  rescue StandardError
    raise ArgumentError, "Invalid public key"
  end

  def encode_point(point, compression:)
    ECDSA::Format::PointOctetString.encode(point, compression: compression)
  end

  def encode_wif(priv_hex, compressed:)
    priv_bytes = [priv_hex].pack("H*")
    data = [MAINNET_PRIVATE_PREFIX].pack("C") + priv_bytes
    data << "\x01" if compressed
    encode_base58check(data)
  end

  def pubkey_bytes_to_address(bytes)
    versioned = [MAINNET_P2PKH_PREFIX].pack("C") + hash160(bytes)
    encode_base58check(versioned)
  end

  def hash160(bytes)
    Digest::RMD160.digest(Digest::SHA256.digest(bytes))
  end

  def bytes_to_hex(bytes)
    bytes.unpack1("H*")
  end

  def hex_to_bytes(hex)
    raise ArgumentError, "Invalid hex" unless hex.is_a?(String) && hex.match?(/\A[0-9a-fA-F]+\z/) && hex.length.even?

    [hex].pack("H*")
  rescue StandardError
    raise ArgumentError, "Invalid hex"
  end

  def encode_base58check(data)
    encode_base58(data + checksum_bytes(data))
  end

  def checksum_bytes(data)
    Digest::SHA256.digest(Digest::SHA256.digest(data))[0, 4]
  end

  def encode_base58(data)
    int = data.bytes.reduce(0) { |total, byte| (total << 8) + byte }
    result = String.new

    while int.positive?
      int, remainder = int.divmod(58)
      result.prepend(BASE58_ALPHABET[remainder])
    end

    leading_zero_count = data.each_byte.take_while(&:zero?).count
    ("1" * leading_zero_count) + result
  end

  def decode_base58(str)
    return nil unless str.is_a?(String) && !str.empty?

    int = 0
    str.each_char do |char|
      digit = BASE58_INDEX[char]
      return nil if digit.nil?
      int = int * 58 + digit
    end

    bytes = []
    while int.positive?
      int, remainder = int.divmod(256)
      bytes.unshift(remainder)
    end

    leading_zero_count = str.each_char.take_while { |c| c == "1" }.count
    ([0] * leading_zero_count + bytes).pack("C*")
  end
end
