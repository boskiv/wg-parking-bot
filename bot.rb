# frozen_string_literal: true

require 'telegram/bot'
require 'mongoid'

token = ENV['WG_BOT_TOKEN']

Mongoid.load!('mongoid.yml', :parking)

class Person
  include Mongoid::Document
  field :first_name
end

Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
  bot.logger.debug('Bot has been started')

  bot.listen do |message|
    case message.text
    when '/start'
      person = Person.new
      person.first_name = message.from.first_name
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    end
  end
end
