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
  def launchctl(command)
    puts "ruby -I#{@libdir} #{@bindir}/launchctl.rb #{command}"
    `ruby -I#{@libdir} #{@bindir}/launchctl.rb #{command}`.chomp
  end

  def setup
    @libdir = __dir__ + '/../lib'
    @bindir = __dir__ + '/../bin'

    @pid = Process.fork
    if @pid.nil?
       #ENV['DEBUG'] = 'yes'
       exec "ruby -I#{@libdir} #{@bindir}/launchd.rb"
    end
  end
end
