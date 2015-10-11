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

class Launch::FileMonitor::Entr
  @@entr = `which entr 2>&1` or raise 'entr not found'
  @@entr.chomp!
  
  def initialize
    @files = []
    @dirs = []
    @command = '/bin/false'
  end
  
  # Add [+files+] to the set of files to be monitored
  def watch_files(files)
    @files.concat files
    self
  end

  def watch_directories(dirs)
    @dirs.concat dirs
    self
  end
  
  # Register [+command+] to be executed when files have changed 
  def execute(command)
    @command = command
    self
  end
  
  # Return the shell command used to launch the monitoring program
  def command
    if @files.length > 0 && @dirs.length > 0
      raise 'watching files AND directories is not supported'
    elsif @files.length > 0
      "echo #{@files.join(' ')} | #{@@entr} #{@command}"
    elsif @dirs.length > 0
      "echo #{@dirs.join(' ')} | #{@@entr} -d #{@command}"     
    else
      raise 'must specify files or dirs to monitor'     
    end
  end
end