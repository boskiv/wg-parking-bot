# frozen_string_literal: true

class Raffle
  include Mongoid::Document
  field :date, type: Date, default: Date.today
  embeds_many :winners, class_name: 'User'

  def shuffle(users)
    last_raffle = Raffle.last
    filtered_users = users - last_raffle.winners
    winners = filtered_users.sample(3)
    winners
  end
end