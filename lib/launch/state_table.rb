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

# A global state table of all jobs
class Launch::StateTable

  def listen_sockets
    return [] if @jobs.empty?
    @jobs.map { |job| job.sockets }.flatten
  end

  def initialize
    @logger = Launch::Log.instance.logger
    @context = Launch::Context.new
    @jobs = []
  end
  
  def load(parsed_plist)
    @jobs << Launch::Job.new.load(parsed_plist).start
  end

  def load_all_jobs
    search_path = @context.search_path
    jobfiles = []
    @logger.debug "search_path=#{search_path.join ':'}"
    search_path.each { |dir| jobfiles << Dir.glob("#{dir}/*.plist") }
    jobfiles.flatten!
    @logger.debug "found jobs: #{jobfiles.join ', '}"
    jobfiles.each do |path|
      @jobs << Launch::Job.new(YAML.load_file(path))
    end
  end

  def setup_activation
    @logger.debug "setting up socket/IPC activation"
    @jobs.each { |job| job.setup }
  end

  def start_all_jobs
    @logger.debug "starting all jobs"
    @jobs.each { |job| job.start }
  end

  def <<(job)
    @jobs << job
  end

  def socket_owner(socket)
    @jobs.select { |job| job.sockets.include? socket }[0]
  end

  def job(label)
    @jobs.select { |job| job.label == label }[0]
  end

  def shutdown
    @jobs.each { |job| job.stop if job.running? }
  end

  def reap(status)
    job = @jobs.select { |job| job.pid == status.pid }
    if job.length == 0
      @logger.warn "child died but not found in table"
    else
      job[0].reap status
    end
  end

  # list all jobs in the launchctl(1) format
  def list
    format = "%-8s %-8s %s\n"
    res = sprintf format, 'PID', 'Status', 'Label'
    @jobs.each do |job| 
      pid = job.pid.nil? ? '-' : job.pid
      res += sprintf format, pid, job.last_exit_code, job.label 
    end
    res
  end
end
