== NotifyBot

Used to notify an IRC channel of outage messages

These can come from 2 different sources
- Uptimerobot
- `check_mk` via a named pipe

This is based upon an original idea from
`https://notes.benv.junerules.com/check_mk-custom-notifications-irc/`
and rewritten from scratch in ruby.

It has since been enhanced to accept outage notifications
from https://uptimerobot.com
