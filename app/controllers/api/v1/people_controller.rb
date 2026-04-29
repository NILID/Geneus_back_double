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

      def update
        person = Person.find_for_api!(params[:id])
        if person.update(api_person_attributes)
          render json: { person: Api::V1::PersonSerializer.new(person).as_json }
        else
          render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Person not found' }, status: :not_found
      end

      private

      def api_person_attributes
        permitted = params.require(:person).permit(
          :name,
          :gender,
          :bio,
          :date_of_birth,
          :date_of_death,
          :location_of_birth,
          :location_of_death,
          { parentship_attributes: %i[id father_id mother_id] },
          partner_ids: []
        )
        h = permitted.to_unsafe_h
        %w[date_of_birth date_of_death].each do |key|
          h[key] = nil if h[key].blank?
        end
        h
      end
    end
  end
end
