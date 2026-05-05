# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action :authenticate_user!
        before_action :set_user, only: [:update]

        def index
          authorize! :read, User
          users = User.order(:email)
          render json: {
            users: users.map { |u| serialize_user(u) }
          }
        end

        def update
          authorize! :update_role, @user
          new_role = user_role_param
          if @user.role == 'admin' && new_role != 'admin' && single_admin_in_system?
            return render json: { errors: ['Должен остаться хотя бы один администратор'] },
                          status: :unprocessable_entity
          end

          if @user.update(role: new_role)
            render json: { user: serialize_user(@user) }
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def user_role_param
          params.require(:user).permit(:role).fetch(:role)
        end

        def single_admin_in_system?
          User.where(role: 'admin').count <= 1
        end

        def serialize_user(u)
          {
            id: u.id,
            email: u.email,
            role: u.role,
            person_id: u.person_id
          }
        end
      end
    end
  end
end
