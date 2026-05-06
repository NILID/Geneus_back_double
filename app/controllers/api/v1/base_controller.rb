# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include Devise::Controllers::Helpers
      include CanCan::ControllerAdditions

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from CanCan::AccessDenied, with: :render_forbidden

      # JSON often contains short-lived Active Storage signed URLs; browsers (especially Safari)
      # may reuse a cached response and keep expired blob URLs in the SPA.
      after_action :disable_http_caching_for_json_api

      private

      def disable_http_caching_for_json_api
        return unless response.content_type&.include?('application/json')

        response.set_header('Cache-Control', 'private, no-store, must-revalidate')
        response.set_header('Pragma', 'no-cache')
      end

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
