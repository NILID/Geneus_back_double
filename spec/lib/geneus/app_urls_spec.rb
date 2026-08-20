# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geneus::AppUrls do
  around do |example|
    previous_frontend = ENV['FRONTEND_URL']
    previous_backend = ENV['BACKEND_PUBLIC_URL']
    ENV['FRONTEND_URL'] = 'https://tree.example.test'
    ENV['BACKEND_PUBLIC_URL'] = 'https://api.example.test'
    example.run
  ensure
    previous_frontend.nil? ? ENV.delete('FRONTEND_URL') : ENV['FRONTEND_URL'] = previous_frontend
    previous_backend.nil? ? ENV.delete('BACKEND_PUBLIC_URL') : ENV['BACKEND_PUBLIC_URL'] = previous_backend
  end

  it 'builds frontend person and media links' do
    person = create(:person, chart_id: 'abc')
    expect(described_class.frontend_base).to eq('https://tree.example.test')
    expect(described_class.person_url(person)).to eq('https://tree.example.test/person/abc')
    expect(described_class.media_url).to eq('https://tree.example.test/media')
    expect(described_class.backend_base).to eq('https://api.example.test')
  end
end
