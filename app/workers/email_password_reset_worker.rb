# frozen_string_literal: true

class EmailPasswordResetWorker
  class DeliveryError < StandardError; end

  include Sidekiq::Worker
  sidekiq_options queue: "email_password_resets"

  def perform(user_id, token)
    user = User.find(user_id)

    uri = URI("https://api.mailgun.net/v3/mg.musicbox.fm/messages")
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request(uri, user, token))
    end

    raise DeliveryError unless res.is_a?(Net::HTTPSuccess)
  end

  private

  def request(uri, user, token)
    template_variables = {
      name: user.name,
      token: token,
      email: URI.encode_www_form_component(user.email)
    }

    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      from: "Truman at Musicbox <truman@musicbox.fm>",
      to: "#{user.name} <#{user.email}>",
      subject: "Musicbox Password Reset",
      template: "password-reset",
      "h:X-Mailgun-Variables": JSON.generate(template_variables)
    )

    req.basic_auth("api", ENV["MAILGUN_KEY"])
    req
  end
end
