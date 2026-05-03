# frozen_string_literal: true

module Api
  module V1
    module People
      class FactsController < BaseController
        before_action :authenticate_user!
        before_action :set_person

        def index
          facts = @person.person_facts.includes(:user).newest_first
          render json: {
            person_facts: facts.map { |f| Api::V1::PersonFactSerializer.new(f).as_json }
          }
        end

        def create
          permitted = params.require(:person_fact).permit(:body)
          fact = @person.person_facts.build(
            user: current_user,
            body: normalize_body(permitted[:body])
          )

          unless fact.save
            render json: { errors: fact.errors.full_messages }, status: :unprocessable_entity
            return
          end

          render json: {
            person_fact: Api::V1::PersonFactSerializer.new(fact).as_json
          }, status: :created
        end

        private

        def set_person
          @person = Person.find_for_api!(params[:person_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Person not found' }, status: :not_found
        end

        def normalize_body(value)
          value.to_s.strip
        end
      end
    end
  end
end
