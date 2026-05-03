# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true, counter_cache: true

  MAX_BODY = 5000

  validates :body, presence: true, length: { maximum: MAX_BODY }
end
