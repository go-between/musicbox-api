# frozen_string_literal: true

RSpec.shared_examples "a mailgun worker" do
  it "posts to mailgun with the designated payload" do
    stub_request(:post, "https://api.mailgun.net/v3/mg.musicbox.fm/messages")
      .with(body: payload)
      .to_return(status: 200, body: "", headers: {})

    described_class.new.perform(*arguments)
  end
end
