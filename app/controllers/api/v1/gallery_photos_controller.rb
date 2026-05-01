# frozen_string_literal: true

module Api
  module V1
    class GalleryPhotosController < BaseController
      before_action :authenticate_user!

      def index
        photos = GalleryPhoto
          .order(created_at: :desc)
          .includes(:user, :tagged_people, image_attachment: :blob)
        render json: {
          gallery_photos: photos.map { |p| Api::V1::GalleryPhotoSerializer.new(p, request: request).as_json }
        }
      end

      def create
        permitted = params.require(:gallery_photo).permit(:caption, :image, person_ids: [])
        raw = params[:gallery_photo]
        photo = current_user.gallery_photos.build(caption: normalize_caption(permitted[:caption]))
        photo.image.attach(permitted[:image]) if permitted[:image].present?

        unless photo.save
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          return
        end

        sync_person_tags!(photo, permitted, raw) if person_ids_in_raw?(raw)

        render json: {
          gallery_photo: Api::V1::GalleryPhotoSerializer.new(photo.reload, request: request).as_json
        }, status: :created
      end

      def update
        photo = current_user.gallery_photos.find(params[:id])
        permitted = params.require(:gallery_photo).permit(:caption, :image, person_ids: [])
        raw = params[:gallery_photo]
        if raw.is_a?(ActionController::Parameters) && (raw.key?(:caption) || raw.key?('caption'))
          photo.caption = normalize_caption(permitted[:caption])
        end
        photo.image.attach(permitted[:image]) if permitted[:image].present?

        unless photo.save
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          return
        end

        sync_person_tags!(photo, permitted, raw) if person_ids_in_raw?(raw)

        render json: {
          gallery_photo: Api::V1::GalleryPhotoSerializer.new(photo.reload, request: request).as_json
        }
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

      def person_ids_in_raw?(raw)
        raw.is_a?(ActionController::Parameters) && (raw.key?(:person_ids) || raw.key?('person_ids'))
      end

      def sync_person_tags!(photo, permitted, raw)
        return unless person_ids_in_raw?(raw)

        ids = normalize_person_ids(permitted[:person_ids])
        people = Person.where(id: ids)
        photo.tagged_people = people.to_a
      end

      def normalize_person_ids(raw)
        Array(raw).flatten.map { |x| Integer(x) rescue nil }.compact.uniq.select(&:positive?)
      end

      def normalize_caption(value)
        return nil if value.nil?

        s = value.to_s.strip
        s.presence
      end
    end
  end
end
