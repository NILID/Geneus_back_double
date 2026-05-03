# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    user
    association :commentable, factory: :idea
    body { 'Согласен, полезная мысль.' }
  end
end
