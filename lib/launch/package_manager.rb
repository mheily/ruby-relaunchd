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
  include Singleton

  def initialize
    @logger = Launch::Log.instance.logger
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
      `pkg query '%n' #{package}`.chomp != ''
    else
      raise 'unsupported pkgtool'
    end
  end

  # Install a [+package+]
  def install(package)
    validate_pkgname package
    case @pkgtool
    when :freebsd_pkg
      system "pkg install --yes --quiet #{package}" or raise "package install of #{package} failed"
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
      system "pkg remove --yes --quiet #{package}" or raise "package remove of #{package} failed"
    else
      raise 'unsupported pkgtool'
    end
  end
  private

  def validate_pkgname(pkg)
    raise 'invalid package name' unless pkg =~ /\A[A-Za-z0-9_.-]+\z/
    pkg
  end

end
