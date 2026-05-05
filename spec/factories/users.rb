# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'Password1!' }
    password_confirmation { 'Password1!' }
    role { 'user' }

    trait :moderator do
      role { 'moderator' }
    end

    trait :admin do
      role { 'admin' }
    end
  end
end
