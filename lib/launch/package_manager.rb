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

# Interface with the OS to manage package installation
class Launch::PackageManager
  require 'tempfile'

  attr_accessor :chroot, :jail_id

  def initialize(container: nil)
    @logger = Launch::Log.instance.logger
    @container = container
    @chroot = nil
    case Gem::Platform.local.os
    when 'linux'
      # TODO: detect yum, apt-get, etc.
    when 'freebsd'
      @pkgtool = :freebsd_pkg
    else
     raise 'unsupported OS: ' + Gem::Platform.local.os
    end
  end

  # Perform one-time setup of the package tool.
  # This should only be called in a container, and runs when the
  # container is created.
  def setup
    if @container.nil?
      @logger.warning 'this method should not be called'
      return
    end

    case @pkgtool
    when :freebsd_pkg
      success = shell_exec "jexec #{@jail_id} sh -c 'ASSUME_ALWAYS_YES=yes pkg -v'"
      raise "setup of pkg(1) failed" unless success
    end
  end

  # Return true if [+package+] is installed.
  def installed?(package)
    validate_pkgname package
    case @pkgtool
    when :freebsd_pkg
      `#{pkg} query '%n' #{package}`.chomp != ''
    else
      raise 'unsupported pkgtool'
    end
  end

  # Install a [+package+]
  def install(package)
    validate_pkgname package
    # TODO: ensure this is deleted
    case @pkgtool
    when :freebsd_pkg
      cmd = "#{pkg} install --yes #{package}"
      unless shell_exec cmd
        raise "package install of #{package} failed."
      end
    else
      raise 'unsupported pkgtool'
    end
  end

  # Uninstall a [+package+]
  def uninstall(package)
    validate_pkgname package
    raise 'package not installed' unless installed?(package)
    case @pkgtool
    when :freebsd_pkg
      system "#{pkg} remove --yes #{package}" or raise "package remove of #{package} failed"
    else
      raise 'unsupported pkgtool'
    end
  end

  private

  # Run a command and capture output in the log
  def shell_exec(command)
    cmd_log = Tempfile.new('launchd.pkgtool')
    @logger.debug "running: #{command}"
    begin
      success = system "#{command} > #{cmd_log.path} 2>&1"
    ensure
      log_output = `cat #{cmd_log.path}`
      @logger.debug "log output:\n" + log_output
      cmd_log.unlink
    end
    success
  end

  def validate_pkgname(pkg)
    raise 'invalid package name' unless pkg =~ /\A[A-Za-z0-9_.-]+\z/
    pkg
  end

  # Shell invocation of pkg(1) with support for jails
  def pkg
    if @container.nil?
      'pkg'
    else
      "jexec #{@jail_id} pkg"
    end
  end
end
