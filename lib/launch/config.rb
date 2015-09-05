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

# Site-specific information about how launchd was installed
class Launch::Config
  include Singleton

  attr_reader :pkgconfigdir
  attr_reader :pkgdatadir
  attr_reader :pkglibdir
  attr_reader :bindir
  attr_reader :sbindir
  attr_reader :mandir
  
  # TODO: make these configurable
  def initialize
    @pkgconfigdir = '/usr/local/etc/launchd'
    @pkgdatadir = '/usr/local/share/launchd'
    @pkglibdir = '/usr/local/lib/launchd'
    @bindir = '/usr/local/bin'
    @sbindir = '/usr/local/sbin'
    @mandir = '/usr/local/man'
  end
end
