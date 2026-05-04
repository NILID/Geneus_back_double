# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        skip_before_action :verify_authenticity_token, raise: false
        respond_to :json

        def create
          build_resource(sign_up_params)
          resource.save
          if resource.persisted?
            sign_in(resource)
            render json: resource.auth_json, status: :created
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def sign_up_params
          params.require(:user).permit(:email, :password, :password_confirmation)
        end
      end
    end
  end
end
