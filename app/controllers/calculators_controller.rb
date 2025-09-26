class CalculatorsController < ApplicationController
  def index
    @input = params[:input].to_s
    @result = BitcoinCalculator.analyze(@input) if params.key?(:input)
  end

  def create
    input = calculator_params[:input].to_s
    redirect_to calculators_path(input: input)
  end

  private

  def calculator_params
    params.require(:calculator).permit(:input)
  end
end
