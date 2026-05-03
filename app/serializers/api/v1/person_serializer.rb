# frozen_string_literal: true

module Api
  module V1
    class PersonSerializer
      def initialize(person, request: nil)
        @person = person
        @request = request
      end

      def as_json
        {
          id: @person.id,
          chart_id: @person.chart_id,
          chart_external_id: @person.chart_external_id,
          first_name: @person.first_name,
          last_name: @person.last_name,
          gender: @person.gender,
          bio: @person.bio,
          date_of_birth: @person.date_of_birth&.iso8601,
          date_of_death: @person.date_of_death&.iso8601,
          location_of_birth: @person.location_of_birth,
          location_of_death: @person.location_of_death,
          birth_latitude: decimal_to_json(@person.birth_latitude),
          birth_longitude: decimal_to_json(@person.birth_longitude),
          death_latitude: decimal_to_json(@person.death_latitude),
          death_longitude: decimal_to_json(@person.death_longitude),
          avatar_url: avatar_url,
          parents: @person.parents.map { |p| summary(p) },
          partners: @person.partners.distinct.map { |p| summary(p) },
          children: @person.children.map { |p| summary(p) },
          tagged_gallery_photos: tagged_gallery_photos_json
        }
      end

      private

      def decimal_to_json(value)
        return nil if value.nil?

        value.to_f
      end

      def tagged_gallery_photos_json
        @person.tagged_gallery_photos.map do |gp|
          {
            id: gp.id,
            caption: gp.caption,
            image_url: gallery_photo_image_url(gp),
            created_at: gp.created_at.iso8601
          }
        end
      end

      def gallery_photo_image_url(gallery_photo)
        return nil if @request.blank? || !gallery_photo.image.attached?

        @request.base_url + Rails.application.routes.url_helpers.rails_blob_path(
          gallery_photo.image,
          only_path: true
        )
      end

      def avatar_url
        return nil if @request.blank? || !@person.avatar.attached?

        @request.base_url + Rails.application.routes.url_helpers.rails_blob_path(
          @person.avatar,
          only_path: true
        )
      end

      def summary(person)
        {
          id: person.id,
          chart_external_id: person.chart_external_id,
          first_name: person.first_name,
          last_name: person.last_name
        }
      end
    end
  end
end
