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

# A job definition as documented in launchd.plist(5)
class Launch::Manifest
  require 'virtus'
  require 'plist'
  require 'json'
  require 'yaml'

  include Virtus.model

  class ResourceLimits
    include Virtus.model
    attribute :core, Integer
    attribute :cpu, Integer
    attribute :data, Integer
    attribute :file_size, Integer
    attribute :file_size, Integer
    attribute :memory_lock, Integer
    attribute :number_of_files, Integer
    attribute :number_of_processes, Integer
    attribute :resident_set_size, Integer
    attribute :stack, Integer
  end

  class Container
    include Virtus.model
    attribute :enable, Boolean, default: false
    attribute :post_create_commands, Array[String]
    attribute :packages, Array[String]
  end

  class Sockets
    include Virtus.model
    attribute :sock_type, String, default: 'stream'
    attribute :sock_passive, Boolean, default: true
    attribute :sock_node_name, String
    attribute :sock_service_name, String
    attribute :sock_family, String
    attribute :sock_protocol, String, default: 'TCP'
    attribute :sock_path_name, String
    attribute :secure_socket_with_key, String
    attribute :sock_path_mode, Integer
    attribute :bonjour, Boolean  # FIXME: can also be string or array
    attribute :multicast_group, String
  end

  #
  # Keep this in sync with launchd.plist(5)
  #
  attribute :label, String
  attribute :disabled, Boolean, default: false
  attribute :user_name, String
  attribute :group_name, String
  #FIXME: define hash elements: attribute :inetdCompatibility, Hash
  attribute :limit_load_to_hosts, Array[String]
  attribute :limit_load_from_hosts, Array[String]
  attribute :limit_load_to_session_type, String
  attribute :program, String
  attribute :program_arguments, Array[String]
  attribute :enable_globbing, Boolean, default: false
  attribute :enable_transactions, Boolean, default: false
  #DEPRECATED: attribute :on_demand, Boolean
  attribute :keep_alive, Boolean, default: false # FIXME: fuzzy typing: can also be Hash
  attribute :run_at_load, Boolean, default: false
  attribute :root_directory, String
  attribute :working_directory, String
  attribute :environment_variables, String
  attribute :umask, Integer
  attribute :time_out, Integer, default: 60  # No reason, just a magic number
  attribute :exit_time_out, Integer, default: 20
  attribute :throttle_interval, Integer, default: 10
  attribute :init_groups, Boolean, default: true
  attribute :watch_paths, Array
  attribute :queue_directories, Array
  attribute :start_on_mount, Boolean, default: false
  attribute :start_interval, Integer, default: 0
  # TODO: complex typing: StartCalendarInterval <dictionary of integers or array of dictionary of integers>
  attribute :standard_in_path, String
  attribute :standard_out_path, String
  attribute :standard_error_path, String
  attribute :debug, Boolean, default: false
  attribute :wait_for_debugger, Boolean, default: false
  attribute :hard_resource_limits, Launch::Manifest::ResourceLimits
  attribute :soft_resource_limits, Launch::Manifest::ResourceLimits
  attribute :nice, Integer
  attribute :process_type, String, default: :standard
  attribute :legacy_timers, Boolean, default: false
  attribute :abandon_process_group, Boolean, default: false
  attribute :low_priority_io, Boolean, default: false
  attribute :launch_only_once, Boolean, default: false
  #TODO: MachServices <dictionary of booleans or a dictionary of dictionaries>
  #FIXME: complex type: Sockets <dictionary of dictionaries... OR dictionary of array of dictionaries...>
  attribute :sockets, Array[Launch::Manifest::Sockets]

  #
  # relaunchd extensions
  #
  attribute :container, Launch::Manifest::Container, default: Launch::Manifest::Container.new

  ## Load a job that has been pre-parsed into a Ruby hash
  def load(obj)
    raise ArgumentError unless obj.kind_of? Hash

    # Override the defaults
    to_snake_case(obj).each do |k,v|
      self.send("#{k}=".to_sym, v)
    end

    self
  end

  # Load a job by parsing a plist file
  def load_file(path)
    raise ArgumentError unless path.kind_of? String
    if path =~ /\.(plist|xml)$/
      obj = Plist::parse_xml(path)
    elsif path =~ /\.(yaml|yml)$/
      obj = YAML.load_file(path)
    elsif path =~ /\.json$/
      obj = JSON.parse(File.read(path))
    else
      raise 'invalid file extension: xml, yaml, or json expected'
    end
    raise "unable to parse #{path}" if obj.nil?
    load obj
    self
  end

  private

  # Convert a hash from "CamelCase" to "snake_case"
  def to_snake_case(hash)
    res = {}
    hash.each do |camel, val|
      if camel.kind_of?(Symbol)
        # assume somebody already snake_Cased it
        snake = camel
      elsif camel.kind_of?(String)
        snake = camel.gsub(/(.)([A-Z])/,'\1_\2').downcase
      else
        raise 'invalid key type'
      end
      if val.kind_of?(Hash)
         val = to_snake_case val
      end
      res[snake] = val
    end
    res
  end
end
