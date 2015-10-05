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

  attr_reader :plist, :pid, :status, :last_exit_code
  attr_reader :sockets

  def initialize
    @pid = -1
    @status = :uninitialized # can be: uninitialized, configured, running, stopped
    @last_exit_code = 0			# last exit status from waitpid()
    @logger = Launch::Log.instance.logger
    @plist = nil
    @sockets = {}
    @active_sockets = []
  end

  # Load a job from a pre-parsed Hash
  def load(hash)
    raise ArgumentError unless hash.kind_of? Hash
    @plist = Launch::Manifest.new.load(hash)
    self
  end

  # Load a job by parsing a plist file
  def load_file(path)
    raise ArgumentError unless path.kind_of? String
    @plist = Launch::Manifest.new.load_file(path)
    self
  end

  def setup 
    #@logger.debug "TODO -- setup socket/ipc activation"
    @logger.debug "DEADWOOD"
    self
  end

  # Start proxying requests from the main host to a container
  def setup_proxy(socktype, family, port)
    raise 'FIXME - only IPv4 supported' unless family == :INET
    Launch::Firewall.new.enable_redirect(socktype, 
	'127.0.1.1', #XXX-FIXME hardcoded
	port)
# DEADWOOD: replaced by firewall
#    raise 'FIXME - only TCP supported' unless socktype == :STREAM
#    @proxy = Launch::Proxy.new(socktype: socktype, 
#    		ip_addr: '127.0.1.1', # XXX-FIXME Hardcoded
#    		port: port)
#    @proxy.start
    self
  end

  def setup_sockets
    @plist.sockets.each do |name, ent|
      setup_socket(name, ent)
    end
  end

  def setup_socket(name, ent)
    port = Socket.getservbyname(ent.sock_service_name)
    raise 'invalid SockServiceName' unless port.kind_of? Integer
    family = case ent.sock_family
    when 'IPv4'
      :INET
    when 'IPv6'
      :INET6
    when 'UNIX'
      :UNIX
    else
      raise ArgumentError, 'invalid SockFamily'
    end
    socktype = case ent.sock_type
    when 'dgram'
      :DGRAM
    when 'stream'
      :STREAM
    when 'raw'
      :RAW
    else
      raise ArgumentError, 'invalid SockType'
    end

    return setup_proxy(socktype, family, port) if container?

    socket = Socket.new(family, socktype, 0)
    socket.close_on_exec = false
    socket.setsockopt(:SOCKET, :REUSEADDR, true)
    socket.bind(Addrinfo.tcp("0.0.0.0", port))
    socket.listen(5)
    @sockets[name] = socket
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
    if container?
      ctr = Launch::Container.new @plist.label, @plist.container
    else
      ctr = Launch::Container::Null.new @plist.label, @plist.container
    end
    ctr.create unless ctr.exists?

    if @plist.sockets.length > 0 and @status == :configured
      setup_sockets 
      return unless container?
    end

    raise 'already started' if @status == :running
 
    args = @plist.program_arguments
    @logger.debug "starting job: #{@plist.label} command=#{args.inspect}"
    @pid = ctr.spawn(args)
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
    @logger.debug "reaped job #{@plist.label} matching pid #{@pid}"
    @status = :stopped
    @last_exit_code = status.exitstatus  # FIXME: is nil when SIGTERM 
    @pid = nil
    self
  end

  private

  def container?
    @plist.container.enable == true
  end
end
