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

# Supervision via the daemontools suite (http://cr.yp.to/daemontools.html)
class Launch::Supervisor::Daemontools < Launch::Supervisor::Base

  def initialize
    super
    @active_jobs = {}
  end

  # Called one time when launchd first starts. Sets up the environment
  # needed by the supervision tool; e.g. creating directories, setting 
  # permissions.
  #
  def setup
    super

    @supervise_path = `which supervise 2>/dev/null`.chomp
    raise 'supervise(8) not found' if $?.exitstatus != 0
    @logger.debug "supervise=#{@supervise_path}"

    @prefix = Launch::Context.new.prefix + '/supervise'
    Dir.mkdir(@prefix, 0700) unless Dir.exist? @prefix
    @logger.debug "prefix=#{@prefix}"
  end

  def start(manifest)
    super

    jobdir = get_jobdir(manifest)
    Dir.mkdir(jobdir, 0700) unless Dir.exist? jobdir
    File.open("#{jobdir}/run", "w") do |f|
      f.write "#!/bin/sh  
      exec #{manifest.program} #{manifest.program_arguments.join(' ')}
      "
    end
    File.chmod 0755, "#{jobdir}/run"
    
    # XXX-FIXME a lot more stuff is needed here
    pid = Process.spawn("supervise #{jobdir}")
    @logger.debug "spawned pid #{pid}"
    Process.detach pid
    @active_jobs[manifest.label] = { pid: pid, manifest: manifest }
  end

  def stop(manifest)
    super
    job = @active_jobs[manifest.label]
    raise 'job not found' if job.nil?

    jobdir = get_jobdir(manifest)

    @logger.debug "using svc to stop #{jobdir}"
    system "svc -d #{jobdir}" or raise 'svc failed'
    sleep 2

    #Kill all the children of the supervise process
    cmd = "pkill -TERM -P #{job[:pid]}"
    @logger.debug "running: #{cmd}"
    system cmd

    @logger.debug "terminating supervisor for to #{jobdir}"
    system "svc -x #{jobdir}" or raise 'svc failed'
  end

  private

  def get_jobdir(manifest)
    @prefix + '/' + manifest.label
  end
end
