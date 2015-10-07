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

# Tests for functionality in Launch::Supervisor
class SupervisorTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  def setup
    @sup = Launch::Supervisor.new
    if ENV['DEBUG']
      @sup.logger = Logger.new($stdout)
      @sup.logger.level = Logger::DEBUG
    end
    @prefix = Launch::Context.new.prefix
  end

  def test_setup
    @sup.setup
    assert Dir.exist? "#{@prefix}/supervise"
  end

  def teardown
    system "svc -d #{@prefix}/supervise/com.example.supervised >/dev/null 2>&1"
    system "svc -x #{@prefix}/supervise/com.example.supervised >/dev/null 2>&1"
  end

  def test_start_and_stop
    @sup.setup
    manifest = Launch::Manifest.new.load({ 
	'Label' => 'com.example.supervised',
	'Program' => '/bin/sleep',
	'ProgramArguments' => ['972493'],
	})

    refute_match /sleep 972493/, `ps axwww`

    @sup.start(manifest)
    assert Dir.exist? "#{@prefix}/supervise/com.example.supervised"
    assert File.exist? "#{@prefix}/supervise/com.example.supervised/run"
    assert File.exist? "#{@prefix}/supervise/com.example.supervised/run"
    assert_match /supervise .*com.example.supervised/, `ps axwww`
    @sup.stop(manifest)
    sleep 2 # give it time to actually exit
    refute_match /supervise .*com.example.supervised/, `ps axwww`
    refute_match /sleep 972493/, `ps axwww`
  end
end
