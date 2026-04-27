# frozen_string_literal: true

module Api
  module V1
    module Auth
      class PasswordsController < Devise::PasswordsController
        skip_before_action :verify_authenticity_token, raise: false
        respond_to :json

        def create
          self.resource = resource_class.send_reset_password_instructions(password_create_params)
          if successfully_sent?(resource)
            head :accepted
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          self.resource = resource_class.reset_password_by_token(password_update_params)
          if resource.errors.empty?
            render json: { message: 'Password has been reset successfully.' }, status: :ok
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def password_create_params
          params.require(:user).permit(:email)
        end

        def password_update_params
          params.require(:user).permit(:reset_password_token, :password, :password_confirmation)
        end
      end
    end
  end
end
