require "csv"
require "net/http"

class PuzzlesController < ApplicationController
  PUZZLE_SOURCE = "https://privatekeys.pw/puzzles/bitcoin-puzzle-tx/export?status=unsolved".freeze

  def index
    @puzzles = fetch_puzzles
  rescue StandardError => e
    Rails.logger.error("Failed to load puzzles: #{e.message}")
    @puzzles = []
    flash.now[:alert] = "Unable to load puzzles right now."
  end

  private

  def fetch_puzzles
    uri = URI.parse(PUZZLE_SOURCE)
    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    CSV.parse(response.body, headers: true).map do |row|
      {
        bits: row["bits"],
        range: [row["range_min"], row["range_max"]],
        address: row["address"],
        btc_value: row["btc_value"],
        hash160: row["hash160_compressed"]
      }
    end
  end
end
