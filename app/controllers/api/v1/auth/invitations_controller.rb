# frozen_string_literal: true

module Api
  module V1
    module Auth
      class InvitationsController < Devise::InvitationsController
        skip_before_action :verify_authenticity_token, raise: false
        respond_to :json

        prepend_before_action :authenticate_inviter!, only: [:create_link]

        def create_link
          self.resource = resource_class.invite!(invite_params, current_inviter) do |u|
            u.skip_invitation = true
          end

          if resource.errors.empty?
            resource.update_column(:invitation_sent_at, Time.current) if resource.invitation_sent_at.blank?
            raw = resource.raw_invitation_token
            invitation_url = invitation_accept_url(raw)
            due_at = resource.invitation_due_at
            render json: {
              email: resource.email,
              invitation_url: invitation_url,
              invitation_text: invitation_share_body(resource.email, invitation_url, due_at),
              invitation_expires_at: due_at&.iso8601(3)
            }, status: :created
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
          end
        end

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

        private

        def invitation_accept_url(raw_token)
          base = ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')
          "#{base}/accept-invitation?invitation_token=#{CGI.escape(raw_token)}"
        end

        def invitation_share_body(email, url, due_at = nil)
          expiry =
            if due_at.present?
              "\nСсылка действительна до #{due_at.in_time_zone.strftime('%d.%m.%Y %H:%M %Z')}.\n"
            else
              "\n"
            end
          <<~TEXT.strip
            Здравствуйте!

            Вас приглашают присоединиться к семейной хронике (учётная запись: #{email}).
            #{expiry}
            Перейдите по ссылке, чтобы задать пароль и войти:
            #{url}

            Если вы не ожидали это приглашение, просто проигнорируйте сообщение.
          TEXT
        end
      end
    end
  end
end
