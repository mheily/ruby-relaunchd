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

# Base class that all firewalls share
class Launch::Firewall::Base

  def initialize
    # The presumed public IPv4 address of the current machine 
    @public_ip = Launch::Network.ip_address(Launch::Network::default_interface)
    # The presumed public-facing interface on the current machine 
    @public_iface = Launch::Network::default_interface
  end

  # Create a NAT rule for an IP address
  def enable_nat(ip_addr)
    raise 'not implemented'
  end

  # Delete a NAT rule for an IP address
  def disable_nat(ip_addr)
    raise 'not implemented'
  end

  # Enable port redirection
  #   socktype: either :STREAM or :DGRAM
  #   ip_addr: the destination IP address
  #   port: the destination port
  def enable_redirect(socktype, ip_addr, port)
    raise 'not implemented'
  end

  # Enable port redirection
  #   socktype: either :STREAM or :DGRAM
  #   ip_addr: the destination IP address
  def disable_redirect(socktype, ip_addr, port)
    raise 'not implemented'
  end

  # Reload the firewall ruleset
  def reload
    raise 'not implemented'
  end
end
