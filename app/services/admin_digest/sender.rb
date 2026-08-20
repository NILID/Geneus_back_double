# frozen_string_literal: true

module AdminDigest
  class Sender
    Result = Struct.new(:sent, :recipients, :payload, keyword_init: true)

    def self.call(now: Time.current)
      new(now: now).call
    end

    def initialize(now: Time.current)
      @now = now
    end

    def call
      payload = Builder.call(now: @now)
      recipients = User.where(role: 'admin').order(:email).to_a
      recipients.each do |admin|
        DigestMailer.monthly(admin, payload).deliver_now
      end
      Result.new(
        sent: recipients.size,
        recipients: recipients.map(&:email),
        payload: payload
      )
    end
  end
end
