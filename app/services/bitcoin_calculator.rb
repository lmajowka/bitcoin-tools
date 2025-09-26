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
      return unless BitcoinUtils.valid_private_key_hex?(input)

      data = BitcoinUtils.derive_from_private(input)

      Result.new(
        input: data[:private_key_hex],
        input_type: :private_key_hex,
        errors: [],
        data: data
      )
    rescue ArgumentError
      nil
    end

    def detect_wif(input)
      priv_hex, _compressed = BitcoinUtils.decode_wif(input)
      data = BitcoinUtils.derive_from_private(priv_hex)

      Result.new(
        input: input,
        input_type: :wif,
        errors: [],
        data: data
      )
    rescue ArgumentError
      nil
    end

    def detect_public_key(input)
      return unless BitcoinUtils.valid_public_key_hex?(input)

      details = BitcoinUtils.public_key_details(input)
      compressed = input.length == 66

      Result.new(
        input: details[:public_key],
        input_type: compressed ? :compressed_public_key : :uncompressed_public_key,
        errors: [],
        data: {
          public_key: details[:public_key],
          hash160: details[:hash160],
          address_p2pkh: details[:address_p2pkh]
        }
      )
    rescue ArgumentError
      nil
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
