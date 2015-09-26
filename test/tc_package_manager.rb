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

require "minitest/autorun"

# Tests for functionality in Launch::PackageManager
class PackageManagerTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  def setup
    @pkg = Launch::PackageManager.new
  end

  # Test the package name sanitizer
  def test_validate_pkgname
    @pkg.send :validate_pkgname, 'foo'
    assert_raises RuntimeError do
      @pkg.send :validate_pkgname, 'foo; rm -rf /tmp/my-precious-data'
    end
  end

  # Test for #installed?
  def test_installed?
    assert @pkg.installed? 'zsh'
    refute @pkg.installed? 'some-package-that-does-not-exist'
  end

  # Test the ability to install/uninstall packages
  def test_install_and_uninstall
    testpkg = 'v7sh' # an obscure FreeBSD package, hopefully not installed
    skip 'TODO - port to linux' unless Gem::Platform.local.os == 'freebsd'
    skip 'requires root privs' unless Process.euid == 0
    skip 'package is already installed' if @pkg.installed? testpkg
    @pkg.install testpkg
    assert @pkg.installed? testpkg
    @pkg.uninstall testpkg
    refute @pkg.installed? testpkg
  end

  # Test the ability to install/uninstall packages in a container
  def test_install_and_uninstall_in_container
    testpkg = 'v7sh' # an obscure FreeBSD package, hopefully not installed
    skip 'TODO - port to linux' unless Gem::Platform.local.os == 'freebsd'
    skip 'requires root privs' unless Process.euid == 0

    name = 'launchd.test_pkg_install'
    c = Launch::Container.new(name)
    system "ezjail-admin delete -f -w #{name}" if c.exists?
    c.create
    c.start
    pkg = Launch::PackageManager.new(container: name)
    pkg.install testpkg
    assert pkg.installed? testpkg
    pkg.uninstall testpkg
    refute pkg.installed? testpkg
    c.destroy
  end

end
