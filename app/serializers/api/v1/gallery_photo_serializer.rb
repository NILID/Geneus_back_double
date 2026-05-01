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
          image_url: image_url,
          created_at: @gallery_photo.created_at.iso8601
        }
      end

      private

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
