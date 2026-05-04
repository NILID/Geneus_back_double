# frozen_string_literal: true

module Api
  module V1
    class PeopleController < BaseController
      before_action :authenticate_user!

      def show
        base = Person.find_for_api!(params[:id])
        person = Person.includes(
          tagged_gallery_photos: [:user, :tagged_people, { image_attachment: :blob }]
        ).find(base.id)
        render json: { person: Api::V1::PersonSerializer.new(person, request: request).as_json }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Person not found' }, status: :not_found
      end

      def update
        person = Person.find_for_api!(params[:id])
        if person.update(api_person_attributes)
          render json: { person: Api::V1::PersonSerializer.new(person, request: request).as_json }
        else
          render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Person not found' }, status: :not_found
      end

      def map_locations
        people = Person.where('birth_latitude IS NOT NULL OR death_latitude IS NOT NULL')
        render json: {
          people: Api::V1::PersonMapLocationSerializer.collection(people)
        }
      end

      private

      def api_person_attributes
        permitted = params.require(:person).permit(
          :first_name,
          :last_name,
          :gender,
          :bio,
          :birth_date_year_only,
          :death_date_year_only,
          :date_of_birth,
          :date_of_death,
          :location_of_birth,
          :location_of_death,
          :birth_latitude,
          :birth_longitude,
          :death_latitude,
          :death_longitude,
          :avatar,
          { parentship_attributes: %i[id father_id mother_id] },
          partner_ids: []
        )
        h = permitted.to_unsafe_h
        %w[date_of_birth date_of_death].each do |key|
          h[key] = nil if h[key].blank?
        end
        %w[bio location_of_birth location_of_death last_name].each do |key|
          h[key] = nil if h[key].blank?
        end
        %w[birth_latitude birth_longitude death_latitude death_longitude].each do |key|
          h[key] = nil if h[key].blank?
        end
        boolean = ActiveModel::Type::Boolean.new
        %w[birth_date_year_only death_date_year_only].each do |key|
          h[key] = boolean.cast(h[key]) if h.key?(key)
        end
        h
      end
    end
  end
end
