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

  # A fake plist to allow the Container object to be created
  def fake_plist
   { 'Enable' => true, 
     'PostCreateCommands' => [],  
   }
  end

  # Test the #create method
  def test_create
    skip 'requires root privs' unless Process.euid == 0
    assert Launch::Container.new('test', fake_plist)
  end

  # Test if a container exists
  def test_exists?
    skip 'requires root privs' unless Process.euid == 0

    c = Launch::Container.new('a-container-that-does-not-exist', fake_plist)
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
    
    c = Launch::Container.new(name, fake_plist)

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
    
    c = Launch::Container.new(name, fake_plist)

    # ensure a clean environment
    system "ezjail-admin delete -f -w #{name}" if c.exists?
    File.unlink(stampfile) if File.exist?(stampfile)
  
    start_launchd
    launchctl "load #{@fixturesdir}/com.example.container.plist"
    sleep 3
    assert File.exist? stampfile 
    File.unlink stampfile
    stop_launchd
  end

  # Test a socket-activated command executed in a jail
  def test_socket_activation
    skip 'requires root privs' unless Process.euid == 0
    skip 'TODO - port to linux' unless Gem::Platform.local.os == 'freebsd'

    name = "relaunchd.test"
    
    c = Launch::Container.new(name, { 
	'Enable' => true, 
	'PostCreateCommands' => [], 
	})

    # ensure a clean environment
    system "ezjail-admin delete -f -w #{name}" if c.exists?
  
    start_launchd
    begin
      launchctl "load #{@fixturesdir}/com.example.container_with_socket.plist"
      sleep 3 # give it time to run async..
      assert_match 'hello world', `nc -w 60 localhost 24820`
    rescue
      raise
    ensure
      stop_launchd
      delete_container name
    end
  end

  # Test the thttpd webserver in a container
  def test_thttpd
    skip 'requires root privs' unless Process.euid == 0
    skip 'TODO - port to linux' unless Gem::Platform.local.os == 'freebsd'

    name = "com.example.thttpd"
    
    c = Launch::Container.new(name, { 
	'Enable' => true, 
	'PostCreateCommands' => [], 
	})

    # ensure a clean environment
    system "ezjail-admin delete -f -w #{name}" if c.exists?
  
    start_launchd
    begin
      launchctl "load #{@fixturesdir}/com.example.thttpd.plist"
      count = 0
      sleep 3 # KLUDGE: allow jail to be created
      loop do
        if system "jexec com_example_thttpd pgrep thttpd"
          break
        else
	  sleep 1
	  count += 1
	  raise 'timeout' if count > 60
        end
      end
      hostname = `hostname`.chomp
      public_ip_addr = `getent hosts #{hostname} | cut -f1 -d' '`.chomp
      assert_match 'thttpd', `curl --silent http://127.0.1.1/`,
	"curl of FIXME-fake_direct_jail_IP failed"
      assert_match 'thttpd', `curl --silent http://#{public_ip_addr}/`,
	"curl of #{public_ip_addr} failed"
      assert_match 'thttpd', `curl --silent http://localhost/`,
	"curl of localhost failed"
    rescue
      raise
    ensure
      stop_launchd
      delete_container name
    end
  end

  private

  # Delete a jail
  def delete_container(name)
    unless ENV['CLEANUP'] == 'no'
      system "ezjail-admin delete -f -w #{name} >/dev/null 2>&1"
    end
  end

end
