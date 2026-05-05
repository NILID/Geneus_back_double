# frozen_string_literal: true

module Api
  module V1
    class AuditsController < BaseController
      before_action :authenticate_user!

      ACTIONS = %w[create update destroy].freeze
      AUDITABLE_TYPES = %w[
        Comment
        GalleryPhoto
        GalleryPhotoPersonTag
        Idea
        Parentship
        Partnership
        Person
        PersonFact
        User
      ].freeze

      def index
        scope = filtered_scope
        total_count = scope.count
        page = [params[:page].to_i, 1].max
        raw_per = params[:per_page].to_i
        per_page = raw_per.positive? ? [[raw_per, 100].min, 1].max : 25

        audits = scope.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page).to_a
        user_ids = audits.map(&:user_id).compact.uniq
        users_by_id = User.where(id: user_ids).index_by(&:id)

        render json: {
          audits: audits.map { |a| Api::V1::AuditSerializer.new(a, users_by_id: users_by_id).as_json },
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: total_pages_for(total_count, per_page)
          }
        }
      end

      def filter_options
        type_scope = Audited::Audit.where(auditable_type: AUDITABLE_TYPES)
        auditable_types = type_scope.distinct.order(:auditable_type).pluck(:auditable_type)

        user_ids = Audited::Audit.where.not(user_id: nil).distinct.pluck(:user_id)
        users = User.where(id: user_ids).order(:email).pluck(:id, :email).map { |id, email| { id: id, email: email } }

        render json: {
          actions: ACTIONS,
          auditable_types: auditable_types,
          users: users
        }
      end

      private

      def filtered_scope
        scope = Audited::Audit.all

        if ACTIONS.include?(params[:action_type].to_s)
          scope = scope.where(action: params[:action_type])
        end

        if params[:user_id].present?
          uid = params[:user_id].to_i
          scope = scope.where(user_id: uid) if uid.positive?
        end

        at = params[:auditable_type].to_s
        scope = scope.where(auditable_type: at) if at.present? && AUDITABLE_TYPES.include?(at)

        if params[:auditable_id].present?
          aid = params[:auditable_id].to_i
          scope = scope.where(auditable_id: aid) if aid.positive?
        end

        q = params[:q].to_s.strip
        if q.present?
          like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
          scope = scope.where('audits.comment LIKE ?', like)
        end

        scope = apply_date_filter(scope, :from, '>=')
        scope = apply_date_filter(scope, :to, '<=')

        scope
      end

      def apply_date_filter(scope, param_key, sql_op)
        raw = params[param_key].presence
        return scope if raw.blank?

        time = Time.zone.parse(raw)
        scope.where("audits.created_at #{sql_op} ?", time)
      rescue ArgumentError, TypeError
        scope
      end

      def total_pages_for(total_count, per_page)
        return 0 if per_page <= 0

        (total_count.to_f / per_page).ceil
      end
    end
  end
end
