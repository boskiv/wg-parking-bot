# frozen_string_literal: true

require 'telegram/bot'
require 'mongoid'
require_relative 'models/user'
require_relative 'models/raffle'
require 'rufus-scheduler'

TELEGRAM_TOKEN = ENV['WG_BOT_TOKEN']
KEYS_NUMBER = ENV['KEYS_NUMBER'] || 6
GROUP_CHAT_ID = ENV['GROUP_CHAT_ID'] || -357_251_490 # default test room
ADMIN_LIST = ENV['ADMIN_LIST'] || ['boskiv']

Mongoid.load!('config/mongoid.yml', :database)

scheduler = Rufus::Scheduler.new

def shuffle(bot, chat_id)
  raffle = Raffle.new
  users = User.where(skip: false).entries
  raffle.shuffle(users, KEYS_NUMBER)
  raffle.save

  response = StringIO.new
  response << "Winners:\n"
  raffle.winners.each do |user|
    response << "- #{user.first_name} #{user.last_name} @#{user.username}\n"
  end

  bot.api.sendMessage(
    chat_id: chat_id,
    text: response.string
  )
end

def register(bot, message)
  User.find_or_create_by(
    username: message.from.username,
    first_name: message.from.first_name,
    last_name: message.from.last_name,
    _id: message.from.id
  )

  bot.api.sendMessage(
    chat_id: message.chat.id,
    text: 'You have signed up successfully. Check your status: `/status`',
    parse_mode: 'Markdown'
  )
end

def skip(bot, message)
  user = User.where(_id: message.from.id).first
  user.skip = !user.skip
  User.where(_id: message.from.id).update(skip: user.skip)
  bot.api.sendMessage(
    chat_id: message.chat.id,
    text: "You skip status update to #{user.skip}"
  )
end

def status(bot, message)
  user = User.where(_id: message.from.id).first
  bot.api.sendMessage(
    chat_id: message.chat.id,
    text: "Your login: #{user.username}.\nYour status: #{user.skip}"
  )
end

def info(bot, message, scheduler)
  raffle = Raffle.last
  response = StringIO.new
  response << "Current month winners:\n"
  raffle.winners.each do |user|
    response << "- #{user.first_name} #{user.last_name} @#{user.username}\n"
  end
  response << "Next raffle in: #{scheduler.jobs.first.next_time}\n"
  bot.api.sendMessage(
    chat_id: message.chat.id,
    text: response.string
  )
end

Telegram::Bot::Client.run(TELEGRAM_TOKEN,
                          logger: Logger.new($stderr)) do |bot|
  bot.logger.debug('Bot has been started')

  scheduler = Rufus::Scheduler.new
  scheduler.cron('@monthly') do
    shuffle(bot, GROUP_CHAT_ID)
  end

  bot.listen do |message|
    case message.text
    when '/register'
      register(bot, message)
    when '/skip'
      skip(bot, message)
    when '/status'
      status(bot, message)
    when '/info'
      info(bot, message, scheduler)
    when '/shuffle'
      if ADMIN_LIST.include? message.from.username
        shuffle(bot, message.chat.id)
      else
        bot.api.sendMessage(
          chat_id: message.chat.id,
          text: 'Your are not allowed to this command'
        )
      end
    else
      bot.logger.info('unknown command')
    end
  end
end
