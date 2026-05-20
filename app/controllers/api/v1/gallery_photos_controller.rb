# frozen_string_literal: true

module Api
  module V1
    class GalleryPhotosController < BaseController
      before_action :authenticate_user!

      def index
        authorize! :read, GalleryPhoto
        photos = GalleryPhoto
          .order(created_at: :desc)
          .includes(:user, gallery_photo_person_tags: :person, image_attachment: :blob)
        render json: {
          gallery_photos: photos.map { |p| Api::V1::GalleryPhotoSerializer.new(p, request: request).as_json }
        }
      end

      def create
        authorize! :create, GalleryPhoto
        permitted = permit_gallery_photo_params
        raw = params[:gallery_photo]
        photo = current_user.gallery_photos.build(caption: normalize_caption(permitted[:caption]))
        photo.taken_year = normalize_taken_year(permitted[:taken_year])
        photo.image.attach(permitted[:image]) if permitted[:image].present?

        unless photo.save
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          return
        end

        if (person_tags_in_raw?(raw) || person_ids_in_raw?(raw)) && !apply_person_tags!(photo, permitted, raw)
          return
        end

        render json: {
          gallery_photo: Api::V1::GalleryPhotoSerializer.new(photo.reload, request: request).as_json
        }, status: :created
      end

      def update
        photo = GalleryPhoto.find(params[:id])
        authorize! :update, photo
        permitted = permit_gallery_photo_params
        raw = params[:gallery_photo]
        if raw.is_a?(ActionController::Parameters) && (raw.key?(:caption) || raw.key?('caption'))
          photo.caption = normalize_caption(permitted[:caption])
        end
        if raw.is_a?(ActionController::Parameters) && (raw.key?(:taken_year) || raw.key?('taken_year'))
          photo.taken_year = normalize_taken_year(permitted[:taken_year])
        end
        photo.image.attach(permitted[:image]) if permitted[:image].present?

        unless photo.save
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          return
        end

        if (person_tags_in_raw?(raw) || person_ids_in_raw?(raw)) && !apply_person_tags!(photo, permitted, raw)
          return
        end

        render json: {
          gallery_photo: Api::V1::GalleryPhotoSerializer.new(photo.reload, request: request).as_json
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Photo not found' }, status: :not_found
      end

      def destroy
        photo = GalleryPhoto.find(params[:id])
        authorize! :destroy, photo
        photo.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Photo not found' }, status: :not_found
      end

      private

      def permit_gallery_photo_params
        params.require(:gallery_photo).permit(
          :caption,
          :image,
          :taken_year,
          person_ids: [],
          person_tags: %i[person_id region_x region_y region_width region_height]
        )
      end

      def person_ids_in_raw?(raw)
        raw.is_a?(ActionController::Parameters) && (raw.key?(:person_ids) || raw.key?('person_ids'))
      end

      def person_tags_in_raw?(raw)
        raw.is_a?(ActionController::Parameters) && (raw.key?(:person_tags) || raw.key?('person_tags'))
      end

      def apply_person_tags!(photo, permitted, raw)
        if person_tags_in_raw?(raw)
          apply_person_tags_from_list!(photo, permitted[:person_tags])
        elsif person_ids_in_raw?(raw)
          apply_person_ids!(photo, permitted[:person_ids])
          true
        else
          true
        end
      end

      def apply_person_tags_from_list!(photo, raw_tags)
        tags = normalize_person_tags(raw_tags)
        ok = true
        GalleryPhoto.transaction do
          photo.gallery_photo_person_tags.destroy_all
          tags.each do |attrs|
            tag = photo.gallery_photo_person_tags.build(attrs)
            next if tag.save

            photo.errors.add(:base, tag.errors.full_messages.join(', '))
            ok = false
            raise ActiveRecord::Rollback
          end
        end
        unless ok
          render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity
          return false
        end
        true
      end

      def apply_person_ids!(photo, raw_ids)
        ids = normalize_person_ids(raw_ids)
        existing = photo.gallery_photo_person_tags.index_by(&:person_id)
        photo.gallery_photo_person_tags.where.not(person_id: ids).destroy_all
        ids.each do |pid|
          next if existing.key?(pid)

          photo.gallery_photo_person_tags.create!(person_id: pid)
        end
      end

      def normalize_person_tags(raw)
        list = Array(raw).map do |item|
          next unless item.is_a?(ActionController::Parameters) || item.is_a?(Hash)

          h = item.to_unsafe_h.transform_keys(&:to_sym) if item.respond_to?(:to_unsafe_h)
          h ||= item.transform_keys(&:to_sym)
          pid = Integer(h[:person_id] || h['person_id']) rescue nil
          next unless pid&.positive?

          attrs = { person_id: pid }
          region = extract_region(h)
          attrs.merge!(region) if region
          attrs
        end.compact

        seen = Set.new
        list.select { |t| seen.add?(t[:person_id]) }
      end

      def extract_region(h)
        keys = %i[region_x region_y region_width region_height]
        vals = keys.map { |k| h[k] || h[k.to_s] }
        return nil if vals.all? { |v| v.nil? || v.to_s.strip == '' }

        {
          region_x: vals[0].to_f,
          region_y: vals[1].to_f,
          region_width: vals[2].to_f,
          region_height: vals[3].to_f
        }
      end

      def normalize_person_ids(raw)
        Array(raw).flatten.map { |x| Integer(x) rescue nil }.compact.uniq.select(&:positive?)
      end

      def normalize_caption(value)
        return nil if value.nil?

        s = value.to_s.strip
        s.presence
      end

      def normalize_taken_year(value)
        return nil if value.nil?

        s = value.to_s.strip
        return nil if s.blank?

        y = Integer(s, 10)
        y.positive? ? y : nil
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
