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

module Common
  require_relative '../lib/launch'

  def launchctl(command)
    `ruby -I#{@libdir} #{@bindir}/launchctl.rb #{command}`.chomp
  end

  def fixture(filename)
    __dir__ + '/fixtures/' + filename
  end

  def start_launchd
    @libdir = __dir__ + '/../lib'
    @bindir = __dir__ + '/../bin'
    @fixturesdir = __dir__ + '/fixtures'

    @pid = Process.fork
    if @pid.nil?
       ENV['DEBUG'] = 'yes'
       exec "ruby -I#{@libdir} #{@bindir}/launchd.rb -f"
    end
  end

  def stop_launchd
    Process.kill 'SIGTERM', @pid
    sleep 1 # hope it shuts down, should probably kill -9 in a bit
    @pid = nil
  end
end
