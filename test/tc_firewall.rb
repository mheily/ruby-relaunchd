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

# Tests for functionality in Launch::Firewall
class FirewallTest < Minitest::Unit::TestCase
  require_relative 'common'
  include ::Common

  def setup
    @fw = Launch::Firewall.new
    @public_ip = Launch::Network.ip_address(Launch::Network::default_interface)
    @public_iface = Launch::Network::default_interface
  end

  def check_ruleset(fw, match)
    buf = fw.send(:ruleset)
    assert_equal match, buf
  end

  # Create a NAT rule for an IP address
  def test_enable_nat
    skip 'requires root privs' unless Process.euid == 0
    @fw.enable_nat '1.2.3.4'
    check_ruleset @fw, "nat pass on #{@public_iface} inet from 1.2.3.4/32 to any -> #{@public_ip}\n"
  end

  # Delete a NAT rule for an IP address
  def test_disable_nat
    skip 'requires root privs' unless Process.euid == 0
    @fw.enable_nat '1.2.3.4'
    @fw.disable_nat '1.2.3.4'
    check_ruleset @fw, "\n"
  end

  def test_enable_redirect
    skip 'requires root privs' unless Process.euid == 0
    @fw.enable_redirect(:STREAM, '1.2.3.4', '80')
    check_ruleset @fw, "rdr pass on #{@public_iface} inet proto tcp from any to #{@public_ip} port = 80 -> 1.2.3.4\n"
  end

  def test_disable_redirect
    skip 'requires root privs' unless Process.euid == 0
    @fw.enable_redirect(:STREAM, '1.2.3.4', '80')
    @fw.disable_redirect(:STREAM, '1.2.3.4', '80')
    check_ruleset @fw, "\n"
  end
end