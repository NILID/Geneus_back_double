# frozen_string_literal: true

FactoryBot.define do
  factory :idea do
    user
    body { 'Описание предложения по улучшению сайта.' }
  end
end
