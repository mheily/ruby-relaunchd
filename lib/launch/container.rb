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

# Factory class to produce objects that interact with OS-specific 
# container functionality.
#
# Examples:
#   * FreeBSD jails
#   * Linux LXC containers
#   * Solaris zones
#
class Launch::Container
  def self.new(name)
    case Gem::Platform.local.os
    when 'linux'
      raise 'TODO - LXC containers'
    when 'freebsd'
      object = Launch::Container::EzJail.allocate
    else
     raise 'unsupported OS: ' + Gem::Platform.local.os
    end
    object.send :initialize, name
    object
  end

  protected

  # Where to send log output from shell commands
  def shell_logfile
    ENV['DEBUG'] ? '' : '>/dev/null 2>&1'
  end
end

# Use the ezjail-admin tool to manage FreeBSD jails
class Launch::Container::EzJail < Launch::Container
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def exists?
    File.exist? "/usr/jails/#{name}"
  end

  def running?
    jails = `jls -N | awk '{ print $1 }'`.split /\n/
    jails.include? sanitized_name
  end

  def create
    # XXX-FIXME need to autodetect the next available loopback IP
    cmd = "ezjail-admin create #{name} 'lo1|127.0.1.1'"
    # XXX-FIXME seems to return non-zero if there are warnings
    system "#{cmd} #{shell_logfile}" # or raise "command failed: #{cmd}"
    raise 'creation failed' unless exists?
  end

  def start
    system "ezjail-admin start #{name} #{shell_logfile}"
    raise 'startup action failed' unless running?
  end

  def stop
    system "ezjail-admin stop #{name} #{shell_logfile}"
    raise 'stop action failed' if running?
  end

  def destroy
    cmd = "ezjail-admin delete -wf #{name} #{shell_logfile}"
    system cmd or raise "command failed: #{cmd}"
  end

  private

  # ezjail sanitizes the name, so we need this name
  def sanitized_name
    @name.gsub(/\./, '_')
  end
end
