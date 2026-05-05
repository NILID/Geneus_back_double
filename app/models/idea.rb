# frozen_string_literal: true

class Idea < ApplicationRecord
  audited

  belongs_to :user
  has_many :comments, as: :commentable, dependent: :destroy

  MAX_BODY = 10_000

  validates :body, presence: true, length: { maximum: MAX_BODY }
end
