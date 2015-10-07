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

# The base class that all Supervisor subclasses inherit from.
class Launch::Supervisor::Base

  attr_accessor :logger

  def initialize
    @logger = Logger.new(Launch::Context.new.logfile) 
  end

  # Called one time when launchd first starts. Sets up the environment
  # needed by the supervision tool; e.g. creating directories, setting 
  # permissions.
  #
  def setup
    @logger.info "initializing the supervisor"
  end

  # Given a parsed launchd.plist(5) object, start a supervised job.
  def start(manifest)
    raise ArgumentError unless manifest.kind_of? Launch::Manifest
    @logger.info "starting a supervised job for #{manifest.label}"
  end

  # Given a parsed launchd.plist(5) object, stop a running job.
  def stop(manifest)
    raise ArgumentError unless manifest.kind_of? Launch::Manifest
    @logger.info "stopping the job for #{manifest.label}"
  end
end
