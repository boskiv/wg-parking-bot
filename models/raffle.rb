# frozen_string_literal: true

# Raffle class to make a raffle
class Raffle
  include Mongoid::Document
  field :date, type: Date, default: Date.today
  embeds_many :winners, class_name: 'User'

  def shuffle(users, keys)
    last_raffle = Raffle.last
    filtered_users = last_raffle.nil? ? users : users - last_raffle.winners
    self.winners = filtered_users.sample(keys)
  end
end
