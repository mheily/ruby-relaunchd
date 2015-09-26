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

# Tests for functionality in Launch::Container
class ContainerTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  # Test the #create method
  def test_create
    skip 'requires root privs' unless Process.euid == 0
    assert Launch::Container.new('test')
  end

  # Test if a container exists
  def test_exists?
    skip 'requires root privs' unless Process.euid == 0

    c = Launch::Container.new('a-container-that-does-not-exist')
    refute c.exists?

    skip 'need to figure out a way to spawn a test container'
    #c = Launch::Container.new('a-container-that-exists')
    #assert c.exists?
  end

  # Test the create/start/stop/destroy lifecycle of a container
  def test_lifecycle_events
    skip 'requires root privs' unless Process.euid == 0
    skip 'TODO - port to linux' unless Gem::Platform.local.os == 'freebsd'

    name = "relaunchd.test"
    
    c = Launch::Container.new(name)

    # ensure a clean environment
    system "ezjail-admin delete -f -w #{name}" if c.exists?
    
    refute c.exists?
    c.create
    assert c.exists?
    refute c.running?
    c.start
    assert c.running?
    c.stop
    refute c.running?
    c.destroy
    refute c.exists?
  end

  # Test a simple command executed in a jail
  def test_simple_jexec
    skip 'requires root privs' unless Process.euid == 0
    skip 'TODO - port to linux' unless Gem::Platform.local.os == 'freebsd'

    name = "relaunchd.test"
    stampfile = '/usr/jails/com.example.container/tmp/launchd-job-stamp'
    
    c = Launch::Container.new(name)

    # ensure a clean environment
    system "ezjail-admin delete -f -w #{name}" if c.exists?
    File.unlink(stampfile) if File.exist?(stampfile)
  
    start_launchd
    launchctl "load #{@fixturesdir}/com.example.container.plist"
    sleep 3 # give it time to run async..
    assert File.exist? stampfile 
    File.unlink stampfile
    stop_launchd
  end
end
