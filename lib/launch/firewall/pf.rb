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

# OpenBSD pf firewall
class Launch::Firewall::Pf < Launch::Firewall::Base

  def initialize
    super
    @nat_addr = [] # List of ip_addrs to provide NAT for
    @rdr_rule = [] # List of rdr rules, in tuples of (socktype, ip_addr, port)
  end

  def enable_nat(ip_addr)
    @nat_addr << ip_addr unless @nat_addr.include? ip_addr
    reload_ruleset
  end

  # Delete a NAT rule for an IP address
  def disable_nat(ip_addr)
    @nat_addr.delete ip_addr
    reload_ruleset
  end

  def enable_redirect(socktype, ip_addr, port)
    @rdr_rule << [socktype, ip_addr, port]
    reload_ruleset
  end

  def disable_redirect(socktype, ip_addr, port)
    @rdr_rule.delete [socktype, ip_addr, port]
    reload_ruleset
  end

  private

  def ruleset
    rules = @nat_addr.map { |ip| nat_rule(ip) }
    rules << @rdr_rule.map { |ent| rdr_rule(*ent) }
    rules.flatten.join("\n") + "\n"
  end

  def nat_rule(ip)
    "nat pass on #{@public_iface} inet from #{ip}/32 to any -> #{@public_ip}"
  end

  def rdr_rule(socktype, ip_addr, port)
    proto = case socktype
    when :STREAM
      'tcp'
    when :DGRAM
      'udp'
    else
      raise ArgumentError
    end
    "rdr pass on #{@public_iface} inet proto #{proto} from any to #{@public_ip} port = #{port} -> #{ip_addr}"
  end

  def reload_ruleset
    outfile = "/var/run/launchd/pf.conf"
    File.open(outfile, "w") { |f| f.write(ruleset) }
    system "pfctl -q -N -a launchd.nat -f #{outfile}" or raise "pfctl-1 failed"
    system "pfctl -q -a launchd.rdr -f #{outfile}" or raise "pfctl-2 failed"
  end
end
