#!/usr/bin/env ruby
#
# Copyright (c) 2015 Mark Heily <mark@heily.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

$LOAD_PATH.unshift "/usr/local/lib/launchd" if $0 == '/usr/local/bin/launchctl'

require 'pp'
require 'socket'
require 'yaml'
require 'launch'

launchd = Launch::Control.new(:client)

#
# MAIN
#
case ARGV.shift
when 'load'
  ARGV.each do |arg|
    raise "#{arg} not found" unless File.exist? arg
    launchd.send('load', Plist::parse_xml(arg))
  end
when 'unload'
when 'submit'
when 'remove'
when 'start'
  launchd.send('start', ARGV[0])
when 'stop'
  launchd.send('stop', ARGV[0])
when 'list'
  launchd.send('list', '')
  result, data = launchd.recv
  puts data
when 'setenv'
when 'unsetenv'
when 'getenv'
when 'export'
when 'getrusage'
when 'log'
when 'limit'
when 'shutdown'
  launchd.send('shutdown', '')
when 'umask'
when 'bslist'
when 'bsexec'
when 'bstree'
when 'managerpid'
when 'manageruid'
when 'managername'
when 'help'
else
  raise ArgumentError, 'unknown command'
end
