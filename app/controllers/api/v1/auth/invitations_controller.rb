# frozen_string_literal: true

module Api
  module V1
    module Auth
      class InvitationsController < Devise::InvitationsController
        skip_before_action :verify_authenticity_token, raise: false
        respond_to :json

        def create
          self.resource = invite_resource
          if resource.errors.empty?
            render json: { message: 'Приглашение отправлено', email: resource.email }, status: :created
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          raw_invitation_token = update_resource_params[:invitation_token]
          self.resource = accept_resource
          if resource.errors.empty?
            resource.after_database_authentication if resource.respond_to?(:after_database_authentication)
            sign_in(resource_name, resource)
            render json: resource.auth_json, status: :ok
          else
            resource.invitation_token = raw_invitation_token if raw_invitation_token.present?
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
