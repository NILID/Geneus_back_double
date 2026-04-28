# frozen_string_literal: true

module Api
  module V1
    class PeopleController < BaseController
      before_action :authenticate_user!

      def show
        person = Person.find_for_api!(params[:id])
        render json: { person: Api::V1::PersonSerializer.new(person).as_json }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Person not found' }, status: :not_found
      end
    end
  end
end
