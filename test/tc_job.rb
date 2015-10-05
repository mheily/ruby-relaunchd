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

# Tests for functionality in Launch::Job
class JobTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  def test_load
    job = Launch::Job.new
    job.load({ 'Label' => 'dynamic', 'Container' => { 'Enable' => true }})
    assert_equal 'dynamic', job.plist.label
    assert job.plist.container.enable
  end

  # Test if you can load a snake_case'd hash
  def test_snake_cased_load
    job = Launch::Job.new
    job.load({ label: 'dynamic', container: { enable: true }})
    assert_equal 'dynamic', job.plist.label
    assert job.plist.container.enable
  end

  def test_load_file
    job = Launch::Job.new
    job.load_file(fixture('com.example.hello_world.plist'))
    assert_equal 'com.example.hello_world', job.plist.label
    assert_equal -1, job.pid
    assert_equal :uninitialized, job.status
    refute job.plist.container.enable
  end

  def test_start
    job = Launch::Job.new
    job.load_file(fixture('com.example.hello_world.plist'))
    job.start
    assert_equal :running, job.status
  end
end
