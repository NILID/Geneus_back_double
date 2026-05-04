# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  belongs_to :person, optional: true

  has_many :gallery_photos, dependent: :destroy
  has_many :ideas, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :person_facts, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :invitable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  has_many :invitations, class_name: 'User', as: :invited_by, dependent: :nullify

  validates :person_id, uniqueness: { allow_nil: true }
  validate :linked_person_must_exist
  validate :password_must_meet_complexity_requirements, if: -> { password.present? }

  def auth_json
    { id: id, email: email, person_id: person_id }
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
