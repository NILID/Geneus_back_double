# frozen_string_literal: true

module Api
  module V1
    module Admin
      class DigestsController < BaseController
        before_action :authenticate_user!

        def create
          authorize! :send, :admin_digest
          result = AdminDigest::Sender.call(recipients: [current_user])
          payload = result.payload
          render json: {
            sent: result.sent,
            recipients: result.recipients,
            period: {
              from: payload.period.from.iso8601,
              to: payload.period.to.iso8601
            },
            counts: {
              birthdays: payload.counts.birthdays,
              new_people: payload.counts.new_people,
              updated_people: payload.counts.updated_people,
              photos: payload.counts.photos,
              photo_tags: payload.counts.photo_tags,
              facts: payload.counts.facts
            }
          }, status: :ok
        end
      end
    end
  end
end
