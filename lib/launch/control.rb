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

# IPC between launchctl and launchd
class Launch::Control
  attr_accessor :socket

  def initialize(role)
    @logger = Launch::Log.instance.logger
    @context = Launch::Context.new

    path = @context.control_path
    case role
    when :server
      File.unlink path if File.exist? path # FIXME: should check pidfile first
      @socket = UNIXServer.new(path)
    when :client
      attempts = 30
      loop do
        begin
        @session = UNIXSocket.new(path)
        rescue Errno::ECONNREFUSED
          sleep 1
        rescue => e
          raise 'Unable to connect to launchd'
        ensure
          attempts -= 1
          raise 'Unable to connect to launchd' if attempts == 0
        end
        break unless @session.nil?
      end
 
    else
      raise ArgumentError
    end
  end

  def accept
    @session = @socket.accept
  end

  def send(command, data)
    message = { 
        'command' => command, 
        'data' => data 
    }.to_yaml
    @session.write message
    @session.puts "."
  end

  def recv 
    buf = []
    while line = @session.gets
      @logger.debug "<<< #{line}"
      break if line == ".\n" 
      buf << line
    end
    yaml = YAML.load(buf.join(''))
    return yaml['command'], yaml['data']
  end
end

