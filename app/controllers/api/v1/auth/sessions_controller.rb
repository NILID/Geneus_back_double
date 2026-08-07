# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        skip_before_action :verify_authenticity_token, raise: false
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          resource.touch_last_seen!(force: true)
          render json: user_json(resource), status: :ok
        end


        def respond_to_on_destroy
          head :no_content
        end

        def user_json(user)
          user.auth_json
        end
      end
    end
  end
end
