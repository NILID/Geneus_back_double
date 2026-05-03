# frozen_string_literal: true

FactoryBot.define do
  factory :person_fact do
    person
    user
    body { 'Участвовал в местном хоре.' }
  end
end
