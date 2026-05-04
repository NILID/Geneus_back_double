class Person < ApplicationRecord
  include Tokenable
  include Rails.application.routes.url_helpers

  after_create :create_parentship

  before_validation :normalize_year_only_date_flags

  has_one_attached :avatar

  has_many :partnerships, :dependent => :destroy
  has_many :partners, through: :partnerships, :source => :partner
 
  has_one :parentship, dependent: :destroy
  has_one :mother, through: :parentship, source: :mother
  has_one :father, through: :parentship, source: :father

  has_many :gallery_photo_person_tags, dependent: :destroy
  has_many :tagged_gallery_photos,
           -> { reorder(created_at: :desc) },
           through: :gallery_photo_person_tags,
           source: :gallery_photo

  has_many :person_facts, dependent: :destroy

  accepts_nested_attributes_for :parentship

  scope :men,   -> { where(gender: 'male') }
  scope :women, -> { where(gender: 'female') }

  # Resolves numeric id first, then +chart_id+ (for /api/v1/people/:id from the SPA).
  def self.find_for_api!(param)
    key = param.to_s
    if key.match?(/\A\d+\z/)
      find(key)
    else
      find_by!(chart_id: key)
    end
  end

  # Tokenable: search / token-create use +first_name+ instead of removed +name+.
  def self.get_attr
    :first_name
  end

  # named_scope :parents, { :include => [ :mother, :father ] }

  validates :first_name, presence: true, length: { minimum: 1 }
  validates :chart_id, uniqueness: { allow_blank: true }
  validates_inclusion_of :gender,
    in: %w( male female ),
    message: 'must be specified'
  validates_date :date_of_birth, {
    :on_or_before => :today,
    :on_or_before_message => 'must be before today',
    :allow_blank => true
  }
  validates_date :date_of_birth, {
    :on_or_before => :date_of_death,
    :on_or_before_message => 'must be before date of death',
    :allow_blank => true
  }
  validates_date :date_of_death, {
    :on_or_before => :today,
    :on_or_before_message => 'must be before today',
    :on_or_after => :date_of_birth,
    :on_or_after_message => 'must be after date of birth',
    :allow_blank => true
  }

  validates :birth_latitude,
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :birth_longitude,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }
  validates :death_latitude,
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :death_longitude,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }

  validate :birth_coordinates_pair
  validate :death_coordinates_pair

  def birth_coordinates_pair
    return if birth_latitude.blank? && birth_longitude.blank?
    return if birth_latitude.present? && birth_longitude.present?

    errors.add(:base, 'Широта и долгота места рождения должны быть заданы вместе или обе пусты')
  end

  def death_coordinates_pair
    return if death_latitude.blank? && death_longitude.blank?
    return if death_latitude.present? && death_longitude.present?

    errors.add(:base, 'Широта и долгота места смерти должны быть заданы вместе или обе пусты')
  end

  def children
    Person
      .joins(:parentship)
      .where(parentships: { father_id: id })
      .or(Person.joins(:parentship).where(parentships: { mother_id: id }))
      .distinct
      .order(:date_of_birth)
  end

  def children_ids
    children.pluck(:id)
  end

  def children_with(partner)
    return [] unless partner

    Person
      .joins(:parentship)
      .where(parentships: { father_id: id, mother_id: partner.id })
      .or(Person.joins(:parentship).where(parentships: { father_id: partner.id, mother_id: id }))
      .distinct
  end

  def add_child( child )
    raise ArgumentError, "Child must be a Person" unless child.is_a?(Person)

    if gender == 'male'
      children_as_father.find_or_create_by(child: child)
    elsif gender == 'female'
      children_as_mother.find_or_create_by(child: child)
    else
      errors.add(:base, "Cannot determine person's gender.")
      false
    end
  end

  def remove_child( child )
    raise ArgumentError, "Child must be a Person" unless child.is_a?(Person)

    association = gender == 'male' ? children_as_father : gender == 'female' ? children_as_mother : nil

    if association
      link = association.find_by(child: child)
      link&.destroy
    else
      errors.add(:base, "Cannot determine person's gender.")
      false
    end
  end

  def all_partners
    # TODO: добавить defacto-партнёров по необходимости (через детей)
    partners.order('partnerships.date_started')
  end

  def parents
    [mother, father].compact
  end

  def chart_external_id
    chart_id.presence || id.to_s
  end

  def family_chart_node(relationship_index: nil)
    {
      id: chart_external_id,
      person_id: id,
      data: family_chart_data,
      rels: family_chart_relationships(relationship_index: relationship_index)
    }
  end

  def family_chart_relationships(relationship_index: nil)
    return relationship_index.rels_for(self) if relationship_index

    relationships = {}

    parent_ids = parents.map(&:chart_external_id)
    spouse_ids = partners.distinct.map(&:chart_external_id)
    child_ids = children.distinct.map(&:chart_external_id)

    relationships[:parents] = parent_ids unless parent_ids.empty?
    relationships[:spouses] = spouse_ids unless spouse_ids.empty?
    relationships[:children] = child_ids unless child_ids.empty?

    relationships
  end

  # === Данные для графа семьи — вынести в отдельный класс в будущем ===
  def family_chart_data
    if Rails.env.development?
      Rails.application.routes.default_url_options[:host] = 'localhost:3000'
    end

    {
      'first name' => first_name,
      'last name' => last_name,
      'avatar' => avatar.attached? ? Rails.application.routes.url_helpers.url_for(avatar) : nil,
      'gender' => family_chart_gender,
      'birthday' => date_of_birth&.iso8601,
      'death' => date_of_death&.iso8601
    }.compact
  end

  def family_chart_gender
    gender == 'female' ? 'F' : 'M'
  end

  def full_name
    [first_name, last_name].compact_blank.join(' ')
  end

  # === Генерация JSON для дерева — ВАЖНО: вынести в отдельный сервис! ===
  def ancestry_json
    person_data = attributes.except('created_at', 'updated_at').merge(
      'children' => [],
      'data' => { '$orn' => 'center' }
    )

    # Дети
    (children_as_father + children_as_mother).uniq.each do |child_ps|
      child = child_ps.child
      person_data['children'] << child.attributes.except('created_at', 'updated_at').merge(
        'data' => { '$orn' => 'top' },
        'children' => []
      )
    end

    # Партнёры
    partnerships.includes(partner: [:parentship]).each do |ps|
      partner = ps.partner
      next unless partner

      person_data['children'] << partner.attributes.except('created_at', 'updated_at').merge(
        'data' => { '$orn' => 'left' },
        'children' => []
      )
    end

    # Родители и предки
    parents.each do |parent|
      parent_data = parent.attributes.except('created_at', 'updated_at').merge(
        'data' => { '$orn' => 'bottom' },
        'children' => []
      )

      # Бабушки/дедушки
      parent.parents.each do |grandparent|
        grandparent_data = grandparent.attributes.except('created_at', 'updated_at').merge(
          'data' => { '$orn' => 'bottom' },
          'children' => []
        )

        # Прабабушки/прадедушки
        grandparent.parents.each do |great_grandparent|
          ggp_data = great_grandparent.attributes.except('created_at', 'updated_at').merge(
            'data' => { '$orn' => 'bottom' }
          )
          grandparent_data['children'] << ggp_data
        end

        parent_data['children'] << grandparent_data
      end

      person_data['children'] << parent_data
    end

    person_data.to_json
  end

  private

  def normalize_year_only_date_flags
    self.birth_date_year_only = false if date_of_birth.blank?
    self.death_date_year_only = false if date_of_death.blank?
  end

  def create_parentship
    Parentship.find_or_create_by(person: self) if gender.present?
  end
end
