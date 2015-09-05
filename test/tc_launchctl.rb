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
# Tests for functionality documented in launchctl(1)
# 
class LaunchctlTest < Minitest::Unit::TestCase
  def test_load ; end
  def test_unload ; end
  def test_submit ; end
  def test_remove ; end
  def test_start ; end
  def test_stop ; end
  def test_list ; end
  def test_setenv ; end
  def test_unsetenv ; end
  def test_getenv ; end
  def test_export; end
  def test_getrusage ; end
  def test_log ; end
  def test_limit ; end
  def test_shutdown ; end
  def test_umask ; end
  def test_bslist ; end
  def test_bsexec ; end
  def test_bstree ; end
  def test_managerpid ; end
  def test_manageruid ; end
  def test_managername ; end
  def test_help ; end
end
