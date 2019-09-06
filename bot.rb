# frozen_string_literal: true

require 'telegram/bot'
require 'mongoid'
require_relative 'models/user'
require_relative 'models/raffle'

TELEGRAM_TOKEN = ENV['WG_BOT_TOKEN']
KEYS_NUMBER = ENV['KEYS_NUMBER'] || 6

Mongoid.load!('config/mongoid.yml', :development)

Telegram::Bot::Client.run(TELEGRAM_TOKEN,
                          logger: Logger.new($stderr)) do |bot|
  bot.logger.debug('Bot has been started')

  bot.listen do |message|
    username = message.from.username
    chat_id = message.chat.id
    msg = message.text
    user_id = message.from.id

    case msg
    when '/register'
      first_name = message.from.first_name
      last_name = message.from.last_name

      User.find_or_create_by(
        username: username,
        first_name: first_name,
        last_name: last_name,
        _id: user_id
      )

      bot.api.sendMessage(
        chat_id: chat_id,
        text: 'You have signed up successfully. Check your status: `/status`',
        parse_mode: 'Markdown'
      )
    when '/skip'
      user = User.where(_id: user_id).first
      user.skip = !user.skip
      User.where(_id: user_id).update(skip: user.skip)
      bot.api.sendMessage(
        chat_id: chat_id,
        text: "You skip status update to #{user.skip}"
      )
    when '/status'
      user = User.where(_id: user_id).first
      bot.api.sendMessage(
        chat_id: chat_id,
        text: "Your login: #{user.username}.\nYour status: #{user.skip}"
      )
    when '/shuffle'
      raffle = Raffle.new
      users = User.where(skip: false).entries
      winners = raffle.shuffle(users, KEYS_NUMBER)
      raffle.winners = winners
      raffle.save
      s = StringIO.new
      winners.each { |user| s << "- #{user.first_name} #{user.last_name} @#{user.username}\n" }

      bot.api.sendMessage(
        chat_id: chat_id,
        text: "Winners: \n#{s.string}",
        parse_mode: 'Markdown'
      )

  end
  end
end
