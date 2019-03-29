# frozen_string_literal: true

module JsonHelper
  def json_body
    expect(0).to eq(1), "Request failed with status #{response.status}" unless response.successful?
    JSON.parse(response.body, symbolize_names: true)
  end
end
