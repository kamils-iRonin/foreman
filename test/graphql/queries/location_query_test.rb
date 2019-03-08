require 'test_helper'

class Queries::LocationQueryTest < ActiveSupport::TestCase
  test 'fetching location attributes' do
    location = FactoryBot.create(:location)

    query = <<-GRAPHQL
      query (
        $id: String!
      ) {
        location(id: $id) {
          id
          name
          title
        }
      }
    GRAPHQL

    location_global_id = Foreman::GlobalId.for(location)
    variables = { id: location_global_id }
    context = { current_user: FactoryBot.create(:user, :admin) }

    result = ForemanGraphqlSchema.execute(query, variables: variables, context: context)
    expected = {
      'location' => {
        'id' => location_global_id,
        'name' => location.name,
        'title' => location.title
      }
    }

    assert_empty result['errors']
    assert_equal expected, result['data']
  end
end
