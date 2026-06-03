# frozen_string_literal: true

require 'pagy'

Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:max_limit] = 100
Pagy::DEFAULT[:overflow] = :empty_page
