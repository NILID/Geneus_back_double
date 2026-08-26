# frozen_string_literal: true

module AdminDigest
  module Format
    MONTHS = %w[
      января февраля марта апреля мая июня
      июля августа сентября октября ноября декабря
    ].freeze

    PERSON_FIELDS = {
      'first_name' => 'Имя',
      'last_name' => 'Фамилия',
      'gender' => 'Пол',
      'bio' => 'Биография',
      'date_of_birth' => 'Дата рождения',
      'date_of_death' => 'Дата смерти',
      'location_of_birth' => 'Место рождения',
      'location_of_death' => 'Место смерти'
    }.freeze

    SKIP_PERSON_FIELDS = %w[
      chart_id created_at updated_at
      birth_latitude birth_longitude death_latitude death_longitude
      birth_date_year_only death_date_year_only
    ].freeze

    class << self
      def date(value)
        d = coerce_date(value)
        return '—' if d.blank?

        "#{d.day} #{MONTHS[d.month - 1]} #{d.year}"
      end

      def datetime(value)
        t = coerce_time(value)
        return '—' if t.blank?

        "#{date(t.to_date)}, #{t.strftime('%H:%M')}"
      end

      def years(n)
        n = n.to_i
        "#{n} #{year_word(n)}"
      end

      def days_after(n)
        n = n.to_i
        return 'сегодня' if n.zero?
        return 'завтра' if n == 1

        "#{n} #{day_word(n)}"
      end

      def person_name(person)
        return 'Без имени' if person.blank?

        name = person.full_name.to_s.strip
        name.present? ? name : 'Без имени'
      end

      def photo_caption(photo)
        cap = photo&.caption.to_s.strip
        cap.presence
      end

      def display_value(field, raw)
        return '—' if blank_value?(raw)

        case field
        when 'gender'
          gender_label(raw)
        when 'date_of_birth', 'date_of_death'
          date(raw)
        when 'bio'
          raw.to_s.strip.truncate(280)
        else
          raw.to_s.strip.truncate(200)
        end
      end

      def person_changes(audited_changes)
        hash = normalize_hash(audited_changes)
        hash.filter_map do |field, delta|
          next if SKIP_PERSON_FIELDS.include?(field)
          next unless PERSON_FIELDS.key?(field)

          old_v, new_v = split_delta(delta)
          next if old_v == new_v

          FieldChange.new(
            label: PERSON_FIELDS[field],
            old_value: display_value(field, old_v),
            new_value: display_value(field, new_v)
          )
        end
      end

      private

      def coerce_date(value)
        case value
        when Date then value
        when Time, ActiveSupport::TimeWithZone then value.to_date
        when String
          Date.parse(value)
        end
      rescue ArgumentError, TypeError
        nil
      end

      def coerce_time(value)
        case value
        when Time, ActiveSupport::TimeWithZone then value
        when Date then value.in_time_zone
        when String
          Time.zone.parse(value)
        end
      rescue ArgumentError, TypeError
        nil
      end

      def blank_value?(raw)
        raw.nil? || (raw.respond_to?(:blank?) && raw.blank?)
      end

      def gender_label(raw)
        case raw.to_s
        when 'male' then 'мужской'
        when 'female' then 'женский'
        else raw.to_s
        end
      end

      def year_word(n)
        mod10 = n % 10
        mod100 = n % 100
        return 'год' if mod10 == 1 && mod100 != 11
        return 'года' if mod10.between?(2, 4) && (mod100 < 10 || mod100 >= 20)

        'лет'
      end

      def day_word(n)
        mod10 = n % 10
        mod100 = n % 100
        return 'день' if mod10 == 1 && mod100 != 11
        return 'дня' if mod10.between?(2, 4) && (mod100 < 10 || mod100 >= 20)

        'дней'
      end

      def normalize_hash(raw)
        return {} if raw.blank?
        return raw.stringify_keys if raw.is_a?(Hash)

        {}
      end

      def split_delta(delta)
        if delta.is_a?(Array)
          [delta[0], delta[1]]
        else
          [nil, delta]
        end
      end
    end
  end
end
