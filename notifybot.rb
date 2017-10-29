#!/usr/bin/ruby
# Author: Stuart Auchterlonie 2017
# License: GPL

require 'cinch'
require 'mkfifo'

class IncomingMessageListener
  def initialize(bot)
    @bot = bot
    if !File.exist?('/var/run/notifybot/notifybot.fifo')
      File.mkfifo('/var/run/notifybot/notifybot.fifo')
    end
    @reader = open('/var/run/notifybot/notifybot.fifo', 'r+')
  end

  def start
    while true
      m_msg = @reader.gets
      if !m_msg.empty?
        @bot.handlers.dispatch(:dispatch_message, nil, m_msg)
      end
    end
  end
end

class DispatchMessagePlugin
  include Cinch::Plugin

  listen_to :dispatch_message
  def listen(m, msg)
    Channel("#mythtv-dev").send "#{msg}"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick            = "MythNotifyBot"
    c.realname        = "MythNotifyBot"
    c.server          = "irc.freenode.org"
    c.channels        = ["#mythtv-dev"]
    c.verbose         = true
    c.plugins.plugins = [DispatchMessagePlugin]
  end
end

bot.loggers.level   = :info
Thread.new { IncomingMessageListener.new(bot).start }
bot.start
