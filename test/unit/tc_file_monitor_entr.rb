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

# Tests for functionality in Launch::FileMonitor::Entr
class EntrTest < Minitest::Unit::TestCase
  require_relative '../common'
  include ::Common

  def setup
    @entr_path ||= `which entr`.chomp
    @entr = Launch::FileMonitor::Entr.new
  end
  
  def test_files
    assert_equal "echo /foo | #{@entr_path} 'bar'", @entr.watch_files(['/foo']).execute('bar').command
  end  

  def test_dirs
    assert_equal "echo /foo | #{@entr_path} -d 'baz'", 
      @entr.watch_directories(['/foo']).execute('baz').command
  end
end
