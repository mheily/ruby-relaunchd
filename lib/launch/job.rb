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

class Launch::Job
  require 'plist'

  attr_reader :plist, :label, :pid, :status, :last_exit_code
  attr_reader :sockets

  def initialize
    @label = '--nil--'
    @pid = -1
    @status = :uninitialized # can be: uninitialized, configured, running, stopped
    @last_exit_code = 0			# last exit status from waitpid()
    @logger = Launch::Log.instance.logger
    @sockets = []
    @active_sockets = []
  end

  # Load a job that has been pre-parsed into a Ruby hash
  def load(obj)
    raise ArgumentError unless obj.kind_of? Hash
    @logger.debug "loading job: #{obj.inspect}"
    @plist = obj
    @label = @plist['Label']
    @status = :configured
    self
  end

  # Load a job by parsing a plist file
  def load_file(path)
    raise ArgumentError unless obj.kind_of? String
    load(Plist::parse_xml(plist))
    self
  end

  def setup 
    #@logger.debug "TODO -- setup socket/ipc activation"
    @logger.debug "DEADWOOD"
    self
  end

  def setup_sockets
    # TODO: handle an array of sockets
    ent = @plist['Sockets']['Listeners']
    port = Socket.getservbyname(ent['SockServiceName'])
    raise 'invalid SockServiceName' unless port.kind_of? Integer
    family = case ent['SockFamily']
    when 'IPv4'
      :INET
    when 'IPv6'
      :INET6
    when 'UNIX'
      :UNIX
    else
      raise ArgumentError, 'invalid SockFamily'
    end
    socktype = case ent['SockType']
    when 'dgram'
      :DGRAM
    when 'stream'
      :STREAM
    when 'raw'
      :RAW
    else
      raise ArgumentError, 'invalid SockType'
    end
    socket = Socket.new(family, socktype, 0)
    socket.close_on_exec = false
    socket.setsockopt(:SOCKET, :REUSEADDR, true)
    socket.bind(Addrinfo.tcp("0.0.0.0", port))
    socket.listen(5)
    @sockets << socket
    @logger.debug "created socket: port=#{port} family=#{family} socktype=#{socktype}"
    @status = :bound
    self
  end

  # socket activation
  def activate
    raise "bad job status: #{@status}" unless @status == :bound
    start
    @active_sockets = @sockets.dup
    @sockets = []
    self
  end

  def start
    if @plist.has_key?('Packages') and @status == :configured
       pkgtool = Launch::PackageManager.instance
       @plist['Packages'].each do |package|
         pkgtool.install(package) unless package.installed?(package)
       end
    end
    if @plist.has_key?('Sockets') and @status == :configured
      return setup_sockets 
    end

    raise 'already started' if @status == :running
 
    @logger.debug "starting job: #{@label} command=#{plist['ProgramArguments'].inspect}"
    @pid = Process.spawn(*@plist['ProgramArguments'], :close_others => false)
    @status = :running
    @logger.debug "child PID #{@pid} now running"
    self
  end

  def running?
    @status == :running
  end

  def stopped?
    @status == :stopped
  end

  def stop
    if @status == :running
      Process.kill 'SIGTERM', @pid
      @status == :stopped
    end
    self
  end

  def reap(status)
    @logger.debug "reaped job #{@label} matching pid #{@pid}"
    @status = :stopped
    @last_exit_code = status.exitstatus  # FIXME: is nil when SIGTERM 
    @pid = nil
    self
  end
end
