# frozen_string_literal: true

class Idea < ApplicationRecord
  belongs_to :user

  MAX_BODY = 10_000

  validates :body, presence: true, length: { maximum: MAX_BODY }
end
