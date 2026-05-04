# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :authenticate_user!

      def show
        render json: current_user.auth_json
      end

      def update
        if current_user.update(user_update_params)
          render json: current_user.auth_json
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_update_params
        raw = params.require(:user).permit(:person_id)
        raw[:person_id] = nil if raw[:person_id].blank?
        raw
      end
    end
  end
end
