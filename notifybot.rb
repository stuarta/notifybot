#!/usr/bin/ruby
# Author: Stuart Auchterlonie 2017-2020
# License: GPL

require 'cinch'
require 'rack'

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

class PrivMsgLogger
  include Cinch::Plugin

  listen_to :private, method: :on_privmsg
  def on_privmsg(m)
    info Cinch::Formatting.unformat(m.params[1])
  end
end

class NotifyBot
  def initialize
    @bot = Cinch::Bot.new do
      configure do |c|
        c.nick            = "DevMythNotifyBot"
        c.realname        = "DevMythNotifyBot"
        c.password        = ENV['IRC_PASSWORD']
        c.server          = "irc.freenode.org"
        c.channels        = ["#mythtv-dev"]
        c.verbose         = true
        c.plugins.plugins = [PrivMsgLogger, DispatchMessagePlugin]
      end
    end
    @bot.loggers.level   = :info
    @wh = WebHandler.new(@bot)
    Thread.new { Rack::Handler::default.run(@wh, :Port => 9080) }
    @bot.start
  end

  def call(env)
    @wh.call(env)
  end
end
