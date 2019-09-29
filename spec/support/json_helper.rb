# frozen_string_literal: true

module JsonHelper
  def json_body
    msg = "Request failed with status #{response.status}"
    expect(0).to eq(1), msg unless response.successful? # rubocop:disable RSpec/ExpectActual
    JSON.parse(response.body, symbolize_names: true)
  end
end
