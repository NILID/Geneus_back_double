# frozen_string_literal: true

module Api
  module V1
    class PeopleController < BaseController
      before_action :authenticate_user!

      def show
        base = Person.find_for_api!(params[:id])
        authorize! :read, base
        person = Person.includes(
          tagged_gallery_photos: [:user, :tagged_people, { image_attachment: :blob }]
        ).find(base.id)
        render json: { person: Api::V1::PersonSerializer.new(person, request: request).as_json }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Person not found' }, status: :not_found
      end

      def update
        person = Person.find_for_api!(params[:id])
        authorize! :update, person
        if person.update(api_person_attributes)
          render json: { person: Api::V1::PersonSerializer.new(person, request: request).as_json }
        else
          render json: { errors: person.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Person not found' }, status: :not_found
      end

      def map_locations
        authorize! :read, Person
        people = Person.where('birth_latitude IS NOT NULL OR death_latitude IS NOT NULL')
        render json: {
          people: Api::V1::PersonMapLocationSerializer.collection(people)
        }
      end

      def recent
        authorize! :read, Person
        people = Person
          .order(updated_at: :desc)
          .limit(12)
          .includes(avatar_attachment: :blob)
        render json: {
          people: people.map { |p| Api::V1::PersonHomeRowSerializer.new(p, request: request).as_json }
        }
      end

      def list
        authorize! :read, Person
        render json: Person.tokens(params[:q])
      end

      def family_chart
        authorize! :read, Person
        people = Person.all.includes(avatar_attachment: [:blob])
        serializer = FamilyChartSerializer.new(people)

        if ActiveModel::Type::Boolean.new.cast(params[:with_connectors])
          render json: { nodes: serializer.nodes, connectors: serializer.connectors }
        else
          render json: serializer.nodes
        end
      end

      def update_tree
        authorize! :update_tree, Person
        payload = tree_update_payload
        FamilyChartTreeSync.new(
          nodes: payload[:nodes],
          removed_ids: payload[:removed_ids]
        ).call

        people = Person.all.includes(avatar_attachment: [:blob])
        render json: { ok: true, nodes: FamilyChartSerializer.new(people).nodes }
      rescue FamilyChartTreeSync::Error => e
        render json: { ok: false, errors: [e.message] }, status: :unprocessable_entity
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

      def tree_update_payload
        if params.key?(:nodes) || params.key?(:removed_ids) || params.key?(:deleted_ids) ||
            params.key?('nodes') || params.key?('removed_ids') || params.key?('deleted_ids')
          return {
            nodes: normalize_nodes_param(params[:nodes] || params['nodes']),
            removed_ids: Array(params[:removed_ids] || params[:deleted_ids] || params['removed_ids'] || params['deleted_ids']).map(&:to_s)
          }
        end

        raw = read_json_body
        return { nodes: [], removed_ids: [] } if raw.blank?

        if raw.is_a?(Array)
          { nodes: raw, removed_ids: [] }
        else
          h = raw.with_indifferent_access
          {
            nodes: h[:nodes] || [],
            removed_ids: Array(h[:removed_ids] || h[:deleted_ids]).map(&:to_s)
          }
        end
      end

      def normalize_nodes_param(nodes)
        return [] if nodes.blank?

        if nodes.is_a?(Array)
          nodes.map do |n|
            n.is_a?(ActionController::Parameters) ? n.to_unsafe_h : n.to_h
          end
        else
          []
        end
      end

      def read_json_body
        body = request.body.read
        request.body.rewind
        return nil if body.blank?

        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
