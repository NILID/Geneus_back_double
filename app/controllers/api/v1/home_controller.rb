# frozen_string_literal: true

module Api
  module V1
    class HomeController < BaseController
      before_action :authenticate_user!

      def stats
        authorize! :read, Person
        render json: { stats: HomeStats.call }
      end
    end
  end
end
