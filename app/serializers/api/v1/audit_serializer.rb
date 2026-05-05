# frozen_string_literal: true

module Api
  module V1
    class AuditSerializer
      def initialize(audit, users_by_id: {})
        @audit = audit
        @users_by_id = users_by_id
      end

      def as_json
        {
          id: @audit.id,
          action: @audit.action,
          auditable_type: @audit.auditable_type,
          auditable_id: @audit.auditable_id,
          user_id: @audit.user_id,
          user_email: user_email,
          comment: @audit.comment,
          audited_changes: normalized_changes,
          version: @audit.version,
          remote_address: @audit.remote_address,
          created_at: @audit.created_at&.iso8601(3)
        }
      end

      private

      def user_email
        uid = @audit.user_id
        return nil unless uid

        @users_by_id[uid]&.email
      end

      def normalized_changes
        raw = @audit.audited_changes
        return {} if raw.blank?

        raw.is_a?(Hash) ? raw.stringify_keys : {}
      end
    end
  end
end
