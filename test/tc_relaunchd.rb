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
    @libdir = __dir__ + '/../lib'
    @bindir = __dir__ + '/../bin'
    @fixturesdir = __dir__ + '/fixtures'

    @pid = Process.fork
    if @pid.nil?
       #ENV['DEBUG'] = 'yes'
       exec "ruby -I#{@libdir} #{@bindir}/launchd.rb"
    end
  end

  def teardown
    Process.kill 'SIGTERM', @pid
    sleep 1 # hope it shuts down, should probably kill -9 in a bit
    @pid = nil
  end

  # Test the ability to specify package dependencies
  def test_Packages
    skip 'FIXME -- this test is broken'
    launchctl "load #{@fixturesdir}/com.example.packages.plist"
    puts launchctl('list')
    assert_match 'packages', launchctl('list')
  end
end
