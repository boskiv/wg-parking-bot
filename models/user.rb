class User
  include Mongoid::Document

  field :first_name, type: String
  field :last_name, type: String
  field :username, type: String
  field :absence, type: Boolean, default: false

end