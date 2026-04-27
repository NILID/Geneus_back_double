# frozen_string_literal: true

module FamilyChart
  # Batch-loads parent, spouse, and child edges for a set of people so chart
  # serialization does not trigger N+1 queries per node.
  class RelationshipIndex
    def initialize(people)
      @people = Array(people)
      @ids = @people.map(&:id).uniq
      @external = {}
      @parents = Hash.new { |h, k| h[k] = [] }
      @spouses = Hash.new { |h, k| h[k] = [] }
      @children = Hash.new { |h, k| h[k] = [] }
      build! if @ids.any?
    end

    # Same shape as Person#family_chart_relationships without an index.
    def rels_for(person)
      pid = person.id
      relationships = {}

      p = @parents[pid]
      relationships[:parents] = p unless p.empty?

      s = @spouses[pid]
      relationships[:spouses] = s unless s.empty?

      c = @children[pid]
      relationships[:children] = c unless c.empty?

      relationships
    end

    private

    def build!
      parent_rows = Parentship.where(person_id: @ids).pluck(:person_id, :father_id, :mother_id)

      partnership_rows = Partnership
        .where(person_id: @ids)
        .order(:date_started, :id)
        .pluck(:person_id, :partner_id)

      child_rows = Parentship
        .where(father_id: @ids).or(Parentship.where(mother_id: @ids))
        .joins(:person)
        .pluck('parentships.person_id', 'parentships.father_id', 'parentships.mother_id', 'people.date_of_birth')

      all_people_ids = @ids.dup
      parent_rows.each { |_, f, m| all_people_ids << f << m }
      partnership_rows.each { |_, partner_id| all_people_ids << partner_id }
      child_rows.each { |child_id, _, _, _| all_people_ids << child_id }
      all_people_ids.compact!
      all_people_ids.uniq!

      @external = Person.where(id: all_people_ids).pluck(:id, :chart_id).each_with_object({}) do |(id, chart_id), h|
        h[id] = chart_id.presence || id.to_s
      end

      parent_rows.each do |person_id, father_id, mother_id|
        @parents[person_id] = [mother_id, father_id].compact.filter_map { |rid| @external[rid] }
      end

      partnership_rows.each do |person_id, partner_id|
        next if partner_id.nil?

        ext = @external[partner_id]
        next unless ext

        arr = @spouses[person_id]
        arr << ext unless arr.include?(ext)
      end

      id_set = @ids.to_set
      sort_epoch = Date.new(1900, 1, 1)
      by_parent = Hash.new { |h, k| h[k] = [] }

      child_rows.each do |child_id, father_id, mother_id, dob|
        by_parent[father_id] << [child_id, dob] if father_id && id_set.include?(father_id)
        by_parent[mother_id] << [child_id, dob] if mother_id && id_set.include?(mother_id)
      end

      by_parent.each do |parent_id, pairs|
        grouped = pairs.group_by(&:first).transform_values { |ps| ps.map(&:last).compact.min }
        ordered_ids = grouped.sort_by { |cid, d| [d || sort_epoch, cid] }.map(&:first)
        @children[parent_id] = ordered_ids.filter_map { |cid| @external[cid] }
      end
    end
  end
end
