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
          comments_count: @gallery_photo.comments_count,
          tagged_people: tagged_people_json
        }
      end

      private

      def tagged_people_json
        tags = @gallery_photo.gallery_photo_person_tags
        tags.map { |tag| person_tag_summary(tag) }
      end

      def person_tag_summary(tag)
        person = tag.person
        summary = {
          id: person.id,
          chart_external_id: person.chart_external_id,
          first_name: person.first_name,
          last_name: person.last_name
        }
        if tag.region?
          summary[:region] = {
            x: tag.region_x.to_f,
            y: tag.region_y.to_f,
            width: tag.region_width.to_f,
            height: tag.region_height.to_f
          }
        end
        summary
      end

      def image_url
        Geneus::BlobPublicPath.url(@gallery_photo.image, request: @request)
      end
    end
  end
end
