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

  # Return true if [+package+] is installed.
  def installed?(package)
    validate_pkgname package
    case @pkgtool
    when :freebsd_pkg
      `pkg #{jail_opts} query '%n' #{package}`.chomp != ''
    else
      raise 'unsupported pkgtool'
    end
  end

  # Install a [+package+]
  def install(package)
    validate_pkgname package
    install_log = Tempfile.new('launchd.pkgtool.install')
    # TODO: ensure this is deleted
    case @pkgtool
    when :freebsd_pkg
      cmd = "pkg #{jail_opts} install --yes #{package}"
      @logger.debug cmd
      success = system "#{cmd} > #{install_log.path} 2>&1"
      log_output = `cat #{install_log.path}`
      @logger.debug log_output
      unless success
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
      system "pkg #{jail_opts} remove --yes #{package}" or raise "package remove of #{package} failed"
    else
      raise 'unsupported pkgtool'
    end
  end
  private

  def validate_pkgname(pkg)
    raise 'invalid package name' unless pkg =~ /\A[A-Za-z0-9_.-]+\z/
    pkg
  end

  # Options for running pkg(1) in a jail environment
  def jail_opts
    if @container.nil?
      ''
    else
      "--jail #{@jail_id}"
      #"--chroot #{@chroot}"
    end
  end
end
