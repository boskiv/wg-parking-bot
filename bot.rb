# frozen_string_literal: true

require 'telegram/bot'

class BotController < Telegram::Bot::UpdatesController
  def start!(*)
    respond_with :message, text: 'Hello!'
  end

  def park!(*)
    respond_with :message, text: 'Parking!'
  end
end

TOKEN = ENV['WG_BOT_TOKEN']
bot = Telegram::Bot::Client.new(TOKEN)

# poller-mode
require 'logger'
logger = Logger.new(STDOUT)

if TOKEN.to_s.empty?
  logger.error('WG_BOT_TOKEN is empty')
  exit(-1)
end
poller = Telegram::Bot::UpdatesPoller.new(bot, BotController, logger: logger)
poller.start

map "/#{TOKEN}" do
  run Telegram::Bot::Middleware.new(bot, BotController)
end
