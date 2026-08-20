# frozen_string_literal: true

module AdminDigest
  class Sender
    Result = Struct.new(:sent, :recipients, :payload, keyword_init: true)

    def self.call(now: Time.current, recipients: nil)
      new(now: now, recipients: recipients).call
    end

    def initialize(now: Time.current, recipients: nil)
      @now = now
      @recipients = recipients
    end

    def call
      payload = Builder.call(now: @now)
      list = recipient_list
      list.each do |user|
        DigestMailer.monthly(user, payload).deliver_now
      end
      Result.new(
        sent: list.size,
        recipients: list.map(&:email),
        payload: payload
      )
    end

    private

    def recipient_list
      if @recipients.nil?
        User.digest_recipients.to_a
      else
        Array(@recipients)
      end
    end
  end
end
