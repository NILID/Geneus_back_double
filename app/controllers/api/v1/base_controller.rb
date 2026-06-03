# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend
      include Devise::Controllers::Helpers
      include CanCan::ControllerAdditions

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from CanCan::AccessDenied, with: :render_forbidden

      private

      def current_ability
        @current_ability ||= Ability.new(current_user)
      end

      def render_forbidden(exception)
        render json: { error: 'Forbidden', message: exception.message }, status: :forbidden
      end

      def render_not_found
        render json: { error: 'Not found' }, status: :not_found
      end
    end
  end
end
