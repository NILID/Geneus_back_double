require 'rails_helper'

RSpec.describe "people/index", type: :view do
  before(:each) do
    @people = create_list(:person, 2, first_name: 'Ivan', last_name: nil)
  end

  it "renders a list of people" do
    render
    assert_select ".card .card-title", :text => "Ivan".to_s,   :count => 2
  end
end
