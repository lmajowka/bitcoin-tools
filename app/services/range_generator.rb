# frozen_string_literal: true

class RangeGenerator
  attr_reader :wallet_number, :generation_method, :percentage

  def initialize(wallet_number:, generation_method: "random", percentage: nil)
    @wallet_number = wallet_number
    @generation_method = generation_method
    @percentage = percentage
  end

  def generate
    errors = validate_params
    return { errors: errors } if errors.any?

    {
      wallet_number: wallet_number,
      range_start: range_start_hex,
      range_end: range_end_hex,
      initial_key: initial_key_hex,
      initial_key_decimal: initial_key_value.to_s,
      generation_method: generation_method,
      percentage: (generation_method == "percentual" ? percentage : nil),
      total_keys: total_keys_in_range
    }
  end

  private

  def validate_params
    errors = []
    errors << "Wallet number must be between 1 and 160" unless wallet_number&.between?(1, 160)
    errors << "Invalid generation method" unless %w[random percentual].include?(generation_method)
    
    if generation_method == "percentual"
      errors << "Percentage must be between 1 and 100" unless percentage&.between?(1, 100)
    end
    
    errors
  end

  def range_start_value
    @range_start_value ||= 2**(wallet_number - 1)
  end

  def range_end_value
    @range_end_value ||= (2**wallet_number) - 1
  end

  def range_start_hex
    @range_start_hex ||= range_start_value.to_s(16).upcase
  end

  def range_end_hex
    @range_end_hex ||= range_end_value.to_s(16).upcase
  end

  def total_keys_in_range
    @total_keys_in_range ||= (range_end_value - range_start_value + 1).to_s
  end

  def initial_key_value
    @initial_key_value ||= calculate_initial_key
  end

  def initial_key_hex
    @initial_key_hex ||= initial_key_value.to_s(16).upcase.rjust(64, "0")
  end

  def calculate_initial_key
    case generation_method
    when "random"
      generate_random_key
    when "percentual"
      generate_percentual_key
    else
      range_start_value
    end
  end

  def generate_random_key
    range_size = range_end_value - range_start_value
    random_offset = SecureRandom.random_number(range_size + 1)
    range_start_value + random_offset
  end

  def generate_percentual_key
    range_size = range_end_value - range_start_value
    offset = (range_size * (percentage / 100.0)).floor
    range_start_value + offset
  end
end
