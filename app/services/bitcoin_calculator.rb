class BitcoinCalculator
  Result = Struct.new(
    :input,
    :input_type,
    :errors,
    :data,
    keyword_init: true
  )

  class << self
    def analyze(raw_input)
      cleaned = raw_input.to_s.strip
      return build_error(cleaned, "Input cannot be blank.") if cleaned.empty?

      detect_private_key(cleaned) ||
        detect_wif(cleaned) ||
        detect_public_key(cleaned) ||
        build_error(cleaned, "Unrecognized input format.")
    rescue StandardError => e
      build_error(cleaned, e.message)
    end

    private

    def detect_private_key(input)
      return unless input.match?(/\A[0-9a-fA-F]{64}\z/)

      priv_hex = input.downcase
      compressed_key = Bitcoin::Key.new(priv_hex, nil, compressed: true)
      uncompressed_key = Bitcoin::Key.new(priv_hex, nil, compressed: false)

      Result.new(
        input: priv_hex,
        input_type: :private_key_hex,
        errors: [],
        data: build_key_data(compressed_key, uncompressed_key)
      )
    end

    def detect_wif(input)
      key = Bitcoin::Key.from_base58(input)

      priv_hex = key.priv
      compressed_key = Bitcoin::Key.new(priv_hex, nil, compressed: true)
      uncompressed_key = Bitcoin::Key.new(priv_hex, nil, compressed: false)

      Result.new(
        input: input,
        input_type: :wif,
        errors: [],
        data: build_key_data(compressed_key, uncompressed_key)
      )
    rescue ArgumentError
      nil
    end

    def detect_public_key(input)
      return unless input.match?(/\A[0-9a-fA-F]{66}\z/) || input.match?(/\A[0-9a-fA-F]{130}\z/)

      key_hex = input.downcase
      compressed = key_hex.length == 66

      Result.new(
        input: key_hex,
        input_type: compressed ? :compressed_public_key : :uncompressed_public_key,
        errors: [],
        data: {
          public_key: key_hex,
          address_p2pkh: Bitcoin.pubkey_to_address(key_hex)
        }
      )
    end

    def build_key_data(compressed_key, uncompressed_key)
      compressed_pub = compressed_key.pub_compressed
      uncompressed_pub = uncompressed_key.pub_uncompressed

      {
        private_key_hex: compressed_key.priv,
        wif_compressed: compressed_key.to_base58,
        wif_uncompressed: uncompressed_key.to_base58,
        public_key_compressed: compressed_pub,
        public_key_uncompressed: uncompressed_pub,
        address_p2pkh_compressed: Bitcoin.pubkey_to_address(compressed_pub),
        address_p2pkh_uncompressed: Bitcoin.pubkey_to_address(uncompressed_pub)
      }
    end

    def build_error(input, message)
      Result.new(
        input: input,
        input_type: :unknown,
        errors: [message],
        data: {}
      )
    end
  end
end
