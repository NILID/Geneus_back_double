class PeopleController < ApplicationController
  before_action :authenticate_user!, only: %i[family_chart update_tree list]
  skip_before_action :verify_authenticity_token, only: [:update_tree]

  before_action :set_person, only: %i[show edit update destroy versions update_father versions_show]

  def index
    @people = Person.all.includes(avatar_attachment: [:blob])
  end

  def list
    list = Person.tokens(params[:q])
    respond_to do |format|
      format.json { render json: list }
    end
  end

  def family_chart
    people = Person.all.includes(avatar_attachment: [:blob])
    serializer = FamilyChartSerializer.new(people)

    if ActiveModel::Type::Boolean.new.cast(params[:with_connectors])
      render json: { nodes: serializer.nodes, connectors: serializer.connectors }
    else
      render json: serializer.nodes
    end
  end

  def update_tree
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

  def versions
  end

  def versions_show
    @person.revert_to( params[:version].to_i )
    puts "\n\n#{params[:version]} :: #{@person.version}\n\n"
  end

  def show
    @person = @person
  end

  def destroy
    @person.destroy

    respond_to do |format|
      format.html { redirect_to( people_url ) }
    end
  end

  private
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

    def set_person
      @person = Person.find(params[:id])
    end
end
