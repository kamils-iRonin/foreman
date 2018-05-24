module Types
  class Model < GraphQL::Types::Relay::BaseObject
    description 'A Model'

    field :id, Integer, resolve: ->(obj, _, _) { obj.id }, null: false
    field :name, String, resolve: ->(obj, _, _) { obj.name }, null: false
    field :info, String, resolve: ->(obj, _, _) { obj.info }, null: true
    field :vendorClass, String, resolve: ->(obj, _, _) { obj.vendor_class }, null: true
    field :hardwareModel, String, resolve: ->(obj, _, _) { obj.hardware_model }, null: true
  end
end
