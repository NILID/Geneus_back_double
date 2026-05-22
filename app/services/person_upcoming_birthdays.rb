# frozen_string_literal: true

class PersonUpcomingBirthdays
  DAYS_PAST = 2
  DAYS_FUTURE = 7

  Row = Struct.new(:person, :days_offset, :occurrence_date, :age, :deceased, keyword_init: true)

  def self.call(reference_date: Date.current)
    new(reference_date: reference_date).call
  end

  def initialize(reference_date: Date.current)
    @today = reference_date
  end

  def call
    offsets = (-DAYS_PAST..DAYS_FUTURE)
    target_by_offset = offsets.index_with { |offset| @today + offset }

    scope = Person
            .where.not(date_of_birth: nil)
            .where(birth_date_year_only: false)
            .includes(avatar_attachment: :blob)

    rows = []
    scope.find_each do |person|
      birth = person.date_of_birth
      offsets.each do |offset|
        target = target_by_offset[offset]
        next unless birthday_on_date?(birth, target)

        rows << Row.new(
          person: person,
          days_offset: offset,
          occurrence_date: target,
          age: target.year - birth.year,
          deceased: person.date_of_death.present?
        )
      end
    end

    rows.sort_by { |row| [row.days_offset, sort_name(row.person)] }
  end

  private

  def sort_name(person)
    [person.last_name.to_s, person.first_name.to_s].join(' ').downcase
  end

  def birthday_on_date?(birth_date, target_date)
    month = birth_date.month
    day = birth_date.day
    if month == 2 && day == 29 && !Date.leap?(target_date.year)
      day = 28
    end
    target_date.month == month && target_date.day == day
  end
end
