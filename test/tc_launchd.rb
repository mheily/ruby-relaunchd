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
# Tests for functionality documented in launchd.plist(5)
# 
class LaunchdTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  def launchctl(command)
    #puts "ruby -I#{@libdir} #{@bindir}/launchctl.rb #{command}"
    `ruby -I#{@libdir} #{@bindir}/launchctl.rb #{command}`.chomp
  end

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

  def test_Label
    launchctl "load #{@fixturesdir}/com.example.snow_white.plist"
    assert_match 'snow_white', launchctl('list')
  end

  def test_Sockets
    plist = "#{@fixturesdir}/com.example.socket_activated.plist"
    unless File.exist? plist
      system "erb #{plist}.erb > #{plist}" or raise 'erb failed'
    end
    launchctl "load #{plist}"
    File.unlink plist
    sleep 3 #KLUDGE
    assert_match 'hello world', `curl -s localhost:24819`.chomp
  end

if false
  def test_Disabled ; end
  def test_UserName ; end
  def test_GroupName ; end
  def test_inetdCompatibility ; end
  def test_LimitLoadToHosts ; end
  def test_LimitLoadFromHosts ; end
  def test_LimitLoadToSessionType ; end
  def test_Program ; end
  def test_ProgramArguments ; end
  def test_EnableGlobbing ; end
  def test_EnableGlobbing ; end
  def test_EnableTransactions ; end
  def test_OnDemand ; end
  def test_KeepAlive ; end
  def test_RunAtLoad ; end
  def test_RootDirectory ; end
  def test_WorkingDirectory ; end
  def test_EnvironmentVariables ; end
  def test_Umask ; end
  def test_TimeOut ; end
  def test_ExitTimeOut ; end
  def test_ThrottleInterval ; end
  def test_InitGroups ; end
  def test_WatchPaths ; end
  def test_QueueDirectories ; end
  def test_StartOnMount ; end
  def test_StartInterval ; end
  def test_StartCalendarInterval ; end
  def test_StandardInPath ; end
  def test_StandardOutPath ; end
  def test_StandardErrorPath ; end
  def test_Debug ; end
  def test_WaitForDebugger ; end
  def test_SoftResourceLimits ; end
  def test_HardResourceLimits ; end
  def test_Nice ; end
  def test_ProcessType ; end
  def test_AbandonProcessGroup ; end
  def test_LowPriorityIO ; end
  def test_LaunchOnlyOnce ; end
  def test_MachServices ; end
end
end
