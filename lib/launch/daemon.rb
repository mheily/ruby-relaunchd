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

class Launch::Daemon
  attr_accessor :daemonize

  def initialize
    @logger = Launch::Log.instance.logger
    @context = Launch::Context.new
    # TODO: create pidfile
    @state = Launch::StateTable.new
    @daemonize = true
  end

  def handle_signals
    if $GOT_SIGTERM
      @logger.debug "got SIGTERM"
      @state.shutdown
      exit 0
    end

    if $GOT_SIGINT
      @logger.debug "got SIGINT"
      @state.shutdown
      exit 1
    end

    if $GOT_SIGCHLD
      loop do
        begin
          pid = Process.waitpid -1, Process::WNOHANG
          if pid.nil?
            @logger.debug "spurious wakeup?"
            next
          end
          @logger.debug "pid #{pid} died with status #{$?.inspect}"
          @state.reap($?.dup)
        rescue Errno::ECHILD
	  break
        end
      end
      # XXX-RACE CONDITION -- if a child dies here, the value of GOT_SIGCHLD will be trashed
      # would like to have an atomic_inc/atomic_dec/atomic_test counter mechanism for the
      # number of children
      $GOT_SIGCHLD = false
    end
    $SIGNAL_READER.read_nonblock(1)
  end

  # FIXME: does not work for some reason
  def start_reaper_thread
    # Lame workaround for the fact that wait*() will immediately return
    # if there are no children 
    if Process.fork.nil?
      s1, s2 = Socket.pair(:UNIX, :DGRAM, 0)
      s2.recv(1)  # Will block forever
    end

    Thread.new do
      loop do
      puts 'reaping'
        wait
      puts 'reaped'
        pp $?
      end
    end
  end
  
  def handle_launchctl(server)
    s = server.accept
    @logger.debug 'incoming connection'

    @logger.debug 'reading data'
    command, data = server.recv
    @logger.debug "command=#{command} data=#{data.inspect}"
    case command
    when 'load'
      @state.load(data)
    when 'list'
      server.send 'ok', @state.list 
    when 'stop'
      @logger.debug "stopping job: #{data}"
      @state.job(data).stop
      #TODO: return value
    when 'shutdown'
      @state.shutdown
      exit 0
    else
      @logger.error 'invalid command'
      server.send 'bad', 'invalid command'
    end

    s.close
  end

  def handle_sockets(sockets)
    @logger.debug "ready sockets: #{sockets.inspect}"
    sockets.each do |socket|
      job = @state.socket_owner(socket)
      job.activate
    end
  end

  def setup_signal_handlers
    $SIGNAL_READER, $SIGNAL_WRITER = IO.pipe
   
    $GOT_SIGINT = false
    Signal.trap(:SIGINT) do
      $GOT_SIGINT = true
      $SIGNAL_WRITER.write_nonblock('.')
    end
    $GOT_SIGTERM = false
    Signal.trap(:SIGTERM) do
      $GOT_SIGTERM = true
      $SIGNAL_WRITER.write_nonblock('.')
    end
    $GOT_SIGCHLD = false
    Signal.trap(:SIGCHLD) do
      $GOT_SIGCHLD = true
      $SIGNAL_WRITER.write_nonblock('.')
    end
  end

  # Redirect the stdio descriptors to the logfile
  def setup_stdio_redirect
    $stdin.close
    $stdout.reopen(@context.logfile, 'w+') 
    $stderr.reopen(@context.logfile, 'w+') 
  end

  def run
    if @daemonize
      Process.daemon(false, true)
      setup_stdio_redirect
    end
    setup_signal_handlers
    ##FIXME: start_reaper_thread
    server = Launch::Control.new(:server)
    @state.load_all_jobs
    @state.setup_activation
    @state.start_all_jobs
    loop do
      begin
      @logger.debug 'waiting for connection'
      ready = IO.select([server.socket, $SIGNAL_READER, @state.listen_sockets].flatten)
      @logger.debug "ready=#{ready.inspect}"

      handle_signals if ready[0].include? $SIGNAL_READER
      handle_launchctl(server) if ready[0].include? server.socket
      sockets = ready[0] & @state.listen_sockets
      handle_sockets(sockets) if sockets.length > 0
      rescue => e
        @logger.error "unhandled exception: #{e.message} at #{e.backtrace.join(' ')}"
        exit(1)
      end
    end
  end
end
