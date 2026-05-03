# frozen_string_literal: true

module Api
  module V1
    class GalleryPhotoSerializer
      def initialize(gallery_photo, request:)
        @gallery_photo = gallery_photo
        @request = request
      end

      def as_json
        {
          id: @gallery_photo.id,
          user_id: @gallery_photo.user_id,
          uploaded_by_email: @gallery_photo.user&.email,
          caption: @gallery_photo.caption,
          taken_year: @gallery_photo.taken_year,
          image_url: image_url,
          created_at: @gallery_photo.created_at.iso8601,
          tagged_people: tagged_people_json
        }
      end

      private

      def tagged_people_json
        @gallery_photo.tagged_people.map { |p| person_tag_summary(p) }
      end

      def person_tag_summary(person)
        {
          id: person.id,
          chart_external_id: person.chart_external_id,
          first_name: person.first_name,
          last_name: person.last_name
        }
      end

      def image_url
        return nil if @request.blank? || !@gallery_photo.image.attached?

        @request.base_url + Rails.application.routes.url_helpers.rails_blob_path(
          @gallery_photo.image,
          only_path: true
        )
      end
    end
  end
end
