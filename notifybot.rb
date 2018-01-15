#!/usr/bin/ruby
# Author: Stuart Auchterlonie 2017-2018
# License: GPL

require 'cinch'
require 'mkfifo'
require 'rack'

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

class WebHandler
  def initialize(bot)
    @bot = bot
  end

  def call(env)
    req = Rack::Request.new(env)
    m_msg = "Service:"
    m_msg << " " << Cinch::Formatting.format(:yellow, req.params['monitorFriendlyName'])
    if (req.params['alertType'] == 1) # Down
      m_msg << " is " << Cinch::Formatting.format(:red, req.params['alertTypeFriendlyName'])
    elsif (req.params['alertType'] == 2) # Up
      m_msg << " is " << Cinch::Formatting.format(:green, req.params['alertTypeFriendlyName'])
    else
      m_msg << " is " << Cinch::Formatting.format(:orange, req.params['alertTypeFriendlyName'])
    end
    m_msg << " - " << Cinch::Formatting.format(:yellow, req.params['alertDetails'])
    @bot.info Cinch::Formatting.unformat(m_msg)
    @bot.handlers.dispatch(:dispatch_message, nil, m_msg)
    res = Rack::Response.new
    res.status = 202
    res.write "Accepted"
    res.finish
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
    c.nick            = "DevMythNotifyBot"
    c.realname        = "DevMythNotifyBot"
    c.server          = "irc.freenode.org"
    c.channels        = ["#mythtv-dev"]
    c.verbose         = true
    c.plugins.plugins = [DispatchMessagePlugin]
  end
end

bot.loggers.level   = :info
wh = WebHandler.new(bot)
Thread.new { Rack::Handler::default.run wh }
Thread.new { IncomingMessageListener.new(bot).start }
bot.start
