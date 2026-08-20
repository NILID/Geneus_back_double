# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = %w[user moderator admin].freeze

  include Devise::JWT::RevocationStrategies::JTIMatcher

  LAST_SEEN_THROTTLE = 10.minutes

  audited except: %i[
    encrypted_password
    reset_password_token
    jti
    invitation_token
    last_seen_at
  ]

  belongs_to :person, optional: true

  has_many :gallery_photos, dependent: :destroy
  has_many :ideas, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :person_facts, dependent: :destroy

  devise :database_authenticatable,
         :recoverable, :validatable, :invitable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  has_many :invitations, class_name: 'User', as: :invited_by, dependent: :nullify

  validates :role, inclusion: { in: ROLES }
  validate :linked_person_must_exist
  validate :password_must_meet_complexity_requirements, if: -> { password.present? }

  # Принявшие приглашение или созданные без invite (не «висящие» инвайты).
  scope :digest_recipients, lambda {
    where.not(email: [nil, ''])
         .where('invitation_token IS NULL OR invitation_accepted_at IS NOT NULL')
         .order(:email)
  }

  def auth_json
    { id: id, email: email, person_id: person_id, role: role }
  end

  def moderator?
    role == 'moderator'
  end

  def admin?
    role == 'admin'
  end

  def genealogy_editor?
    moderator? || admin?
  end

  def touch_last_seen!(force: false)
    return if !force && last_seen_at.present? && last_seen_at > LAST_SEEN_THROTTLE.ago

    update_column(:last_seen_at, Time.current)
  end

  private

  def linked_person_must_exist
    return if person_id.blank?

    errors.add(:person_id, 'указанная персона не найдена') unless Person.exists?(person_id)
  end

  def password_must_meet_complexity_requirements
    return if password.blank?

    unless password.match?(/[A-Z]/)
      errors.add(:password, 'должен содержать хотя бы одну заглавную латинскую букву')
    end
    unless password.match?(/[^A-Za-z0-9]/)
      errors.add(:password, 'должен содержать хотя бы один специальный символ')
    end
  end
end
