# frozen_string_literal: true

class PersonFact < ApplicationRecord
  audited

  belongs_to :person
  belongs_to :user

  MAX_BODY = 5000

  validates :body, presence: true, length: { maximum: MAX_BODY }

  scope :newest_first, -> { order(created_at: :desc) }
end
