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
  def self.new(name, plist)
    platform = Gem::Platform.local.os

    case platform
    when 'linux'
      raise 'TODO - LXC containers'
    when 'freebsd'
      Launch::Container::EzJail.new(name, plist)
    when 'null'
      Launch::Container::Null.new(name, plist)
    else
     raise 'unsupported OS: ' + platform
    end
  end
end

# A common base class for all container types
class Launch::Container::Base
  attr_reader :name, :chroot

  def initialize(name, plist)
    @name = name
    @logger = Launch::Log.instance.logger
    @plist = plist
    # Sanity check the plist
    @plist['PostCreateCommands'] ||= []
  end

  protected

  # Where to send log output from shell commands
  def shell_logfile
    ENV['DEBUG'] ? '' : '>/dev/null 2>&1'
  end
end

# A "null container" that executes everything in the host OS
class Launch::Container::Null < Launch::Container::Base

  def initialize(name, plist)
    super(name, plist)
    @chroot = '/'
  end

  def exists?
    true
  end

  def running?
    true
  end

  def create
    self
  end

  def start
    self
  end

  def stop
    self
  end

  def destroy
    nil
  end

  def spawn(args)
    Process.spawn(*args, :close_others => false)
  end

  def package_manager
    Launch::PackageManager.new
  end
end

# Use the ezjail-admin tool to manage FreeBSD jails
class Launch::Container::EzJail < Launch::Container::Base

  def initialize(name, plist)
    super(name, plist)
    @chroot = "/usr/jails/#{name}"
    @pkgtool = Launch::PackageManager.new(container: @name)
  end

  def exists?
    File.exist? chroot
  end

  def running?
    jails = `jls -N | awk '{ print $1 }'`.split /\n/
    jails.include? sanitized_name
  end

  def create
    # XXX-FIXME need to autodetect the next available loopback IP
    cmd = "ezjail-admin create #{name} 'lo1|127.0.1.1'"
    @logger.debug "creating jail: #{cmd}"
    # XXX-FIXME seems to return non-zero if there are warnings
    system "#{cmd} #{shell_logfile}" # or raise "command failed: #{cmd}"
    raise 'creation failed' unless exists?

    Launch::Firewall.new.enable_nat('127.0.1.1') #XXX-FIXME hardcoded

    start

    system "cp /etc/resolv.conf /usr/jails/#{name}/etc" or raise "cp failed"

    # Install required packages
    @pkgtool.chroot = chroot
    @pkgtool.jail_id = jail_id
    @pkgtool.setup
    if @plist.has_key?('Packages')
      @plist['Packages'].each do |package|
        @pkgtool.install(package) unless @pkgtool.installed?(package)
      end
    end

    # Run the post-create commands
    @plist['PostCreateCommands'].each do |cmd|
      cmd.gsub!('$chroot', chroot)
      @logger.debug "running post-create command: #{cmd}"
      system cmd
      # TODO: log and warn on a non-zero exit status
    end
  end

  def start
    cmd = "ezjail-admin start #{name} #{shell_logfile}"
    @logger.debug "starting jail: #{cmd}"
    system cmd
    raise 'startup action failed' unless running?
    @logger.debug "jail started; jid=#{jail_id}"
  end

  def stop
    cmd = "ezjail-admin stop #{name} #{shell_logfile}"
    @logger.debug "stopping jail: #{cmd}"
    system cmd
    raise 'stop action failed' if running?
  end

  def destroy
    cmd = "ezjail-admin delete -wf #{name} #{shell_logfile}"
    system cmd or raise "command failed: #{cmd}"
  end

  def spawn(args)
    @logger.debug "hello"
    cmd = ['jexec', jail_id].concat(args)
    @logger.debug "spawning: #{cmd.inspect}"
    Process.spawn(*cmd, :close_others => false)
  end

  def package_manager
    @pkgtool
  end

  private

  # ezjail sanitizes the name, so we need this name
  def sanitized_name
    @name.gsub(/\./, '_')
  end

  # The numeric jail ID of the jail
  def jail_id
    `jls -n`.split(/\n/).each do |line|
       tok = line.split(/ /)
       rec = {}
       tok.each { |t| key, val = t.split(/=/) ; rec[key] = val }
       #@logger.debug rec.inspect
       if rec['host.hostname'] == @name
         return rec['jid']
       end
    end
    raise "jail not found"
  end
end
