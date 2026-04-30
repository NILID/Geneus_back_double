require 'rails_helper'

RSpec.describe "people/show", type: :view do
  before(:each) do
    @person = create(:person, first_name: 'Ivan', last_name: nil)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Ivan/)
  end
end
