class FamilyChartSerializer
  def initialize(people = Person.all)
    @people = people
  end

  def nodes
    @nodes ||= begin
      people = @people.is_a?(ActiveRecord::Relation) ? @people.to_a : Array(@people)
      index = FamilyChart::RelationshipIndex.new(people)
      people.map { |person| person.family_chart_node(relationship_index: index) }
    end
  end

  # Optional edge list useful for debugging integrations.
  def connectors
    @connectors ||= begin
      edges = []

      nodes.each do |node|
        source = node[:id]
        rels = node[:rels] || {}

        Array(rels[:parents]).each do |target|
          edges << { from: source, to: target, type: 'parent' }
        end
        Array(rels[:spouses]).each do |target|
          edges << { from: source, to: target, type: 'spouse' }
        end
        Array(rels[:children]).each do |target|
          edges << { from: source, to: target, type: 'child' }
        end
      end

      edges.uniq
    end
  end
end
