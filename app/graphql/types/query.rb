module Types
  class Query < GraphQL::Schema::Object
    graphql_name 'Query'

    field :model, Types::Model,
      function: Queries::FetchField.new(type: Types::Model, model_class: ::Model)

    field :models, Types::Model.connection_type,
      function: Queries::PluralField.new(type: Types::Model, model_class: ::Model)
  end
end
