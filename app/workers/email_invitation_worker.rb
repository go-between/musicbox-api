# frozen_string_literal: true

class EmailInvitationWorker
  class DeliveryError < StandardError; end

  include Sidekiq::Worker
  sidekiq_options queue: "email_invitations"

  def perform(invitation_id)
    invitation = Invitation.find(invitation_id)

    uri = URI("https://api.mailgun.net/v3/mg.musicbox.fm/messages")
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request(uri, invitation))
    end

    raise DeliveryError unless res.is_a?(Net::HTTPSuccess)
  end

  private

  def request(uri, invitation) # rubocop:disable Metrics/MethodLength
    template_variables = {
      inviter_name: invitation.inviting_user.name,
      team_name: invitation.team.name,
      token: invitation.token,
      email: invitation.email
    }

    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      from: "Truman at Musicbox <truman@musicbox.fm>",
      to: "#{invitation.name} <#{invitation.email}>",
      subject: "Your Musicbox Invitation",
      template: "invitation",
      "h:X-Mailgun-Variables": JSON.generate(template_variables)
    )

    req.basic_auth("api", ENV["MAILGUN_KEY"])
    req
  end
end
