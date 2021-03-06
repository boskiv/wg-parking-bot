# frozen_string_literal: true

require 'telegram/bot'
require 'mongoid'
require_relative 'models/user'
require_relative 'models/raffle'
require 'rufus-scheduler'

TELEGRAM_TOKEN = ENV['WG_BOT_TOKEN']
KEYS_NUMBER = ENV['KEYS_NUMBER'].to_i || 6
GROUP_CHAT_ID = ENV['GROUP_CHAT_ID'].to_i || -357_251_490 # default test room
ADMIN_LIST = ENV['ADMIN_LIST'] || ['boskiv']

Mongoid.load!('config/mongoid.yml', :database)

scheduler = Rufus::Scheduler.new

def shuffle(bot, chat_id)
  raffle = Raffle.new
  users = User.where(absence: false).entries
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

def absence(bot, message)
  user = User.where(_id: message.from.id).first
  user.absence = !user.absence
  User.where(_id: message.from.id).update(absence: user.absence)
  bot.api.sendMessage(
    chat_id: message.chat.id,
    text: "You absence status update to #{user.absence}"
  )
end

def status(bot, message)
  user = User.where(_id: message.from.id).first
  bot.api.sendMessage(
    chat_id: message.chat.id,
    text: "Your login: #{user.username}.\nYour absence status: #{user.absence}"
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
  require 'socket'
  TCPServer.new ENV['PORT'] || 8000
  scheduler = Rufus::Scheduler.new
  scheduler.cron('@monthly') do
    shuffle(bot, GROUP_CHAT_ID)
  end

  bot.listen do |message|
    case message.text
    when '/register'
      register(bot, message)
    when '/absence'
      absence(bot, message)
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
