class RangeGeneratorsController < ApplicationController
  def index; end

  def create
    @wallet_number = params.dig(:range, :wallet_number)&.to_i
    @generation_method = params.dig(:range, :generation_method) || "random"
    @percentage = params.dig(:range, :percentage)&.to_f

    generator = RangeGenerator.new(
      wallet_number: @wallet_number,
      generation_method: @generation_method,
      percentage: @percentage
    )

    @result = generator.generate

    render :index
  end
end
