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

class Launch::Context::System
  attr_reader :prefix, :control_path, :search_path, :logfile

  def initialize
    config = Launch::Config.instance
    @prefix = '/var/run/launchd'
    @control_path =  "#{@prefix}/control.socket"
    @search_path = [
      config.pkgdatadir + '/LaunchAgents',
      config.pkgdatadir + '/LaunchDaemons',
      config.pkgconfigdir + '/LaunchAgents',
      config.pkgconfigdir + '/LaunchDaemons',
    ]
    @logfile = '/var/log/launchd.log'
    unless File.exists? @prefix
      Dir.mkdir @prefix
      File.chmod 0700, @prefix
    end
  end
end
