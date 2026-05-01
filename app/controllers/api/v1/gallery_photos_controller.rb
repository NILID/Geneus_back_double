# frozen_string_literal: true

module Api
  module V1
    class GalleryPhotosController < BaseController
      before_action :authenticate_user!

      def index
        photos = GalleryPhoto
          .order(created_at: :desc)
          .includes(:user, image_attachment: :blob)
        render json: {
          gallery_photos: photos.map { |p| Api::V1::GalleryPhotoSerializer.new(p, request: request).as_json }
        }
      end

      def create
        permitted = params.require(:gallery_photo).permit(:caption, :image)
        photo = current_user.gallery_photos.build(caption: normalize_caption(permitted[:caption]))
        photo.image.attach(permitted[:image]) if permitted[:image].present?

        if photo.save
          render json: {
            gallery_photo: Api::V1::GalleryPhotoSerializer.new(photo, request: request).as_json
          }, status: :created
        else
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        photo = current_user.gallery_photos.find(params[:id])
        permitted = params.require(:gallery_photo).permit(:caption, :image)
        raw = params[:gallery_photo]
        if raw.is_a?(ActionController::Parameters) && (raw.key?(:caption) || raw.key?('caption'))
          photo.caption = normalize_caption(permitted[:caption])
        end
        photo.image.attach(permitted[:image]) if permitted[:image].present?

        if photo.save
          render json: {
            gallery_photo: Api::V1::GalleryPhotoSerializer.new(photo, request: request).as_json
          }
        else
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Photo not found' }, status: :not_found
      end

      def destroy
        photo = current_user.gallery_photos.find(params[:id])
        photo.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Photo not found' }, status: :not_found
      end

      private

      def normalize_caption(value)
        return nil if value.nil?

        s = value.to_s.strip
        s.presence
      end
    end
  end
end
