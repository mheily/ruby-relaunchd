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

#
# Tests for functionality in relaunchd that is not present in the 
# original MacOS implementation of launchd.
# 
class RelaunchdTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  def setup
    start_launchd
  end

  def teardown
    stop_launchd
  end

  # Test the ability to specify package dependencies
  def test_Packages
    skip 'requires root privs' unless Process.euid == 0
    launchctl "load #{@fixturesdir}/com.example.packages.plist"
    assert_match 'com.example.packages', launchctl('list')
  end

  # Test the ability to use containers
  def test_Container
    skip 'requires root privs' unless Process.euid == 0
    launchctl "load #{@fixturesdir}/com.example.container.plist"
    assert_match 'com.example.container', launchctl('list')
  end
end
