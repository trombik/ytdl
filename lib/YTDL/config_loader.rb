# frozen_string_literal: true

require "yaml"
require "erb"
require "pathname"

class YTDL
  # A class to load, parse, and validate config file.
  #
  # The file is YAML with erb template. You may use valid erb syntax in the
  # file. Values must conform defined types. Values must be either String or
  # Integer.
  #
  # Use unquoted number in the value for `type` Integer. `"5000"` is String.
  #
  # The following example is invalid because `port` is expected to be Integer.
  #
  # ```yaml
  # download_dir: /tmp
  # port: "5000"
  # ```
  #
  # The following example is valid.
  #
  # ```yaml
  # download_dir: /tmp
  # port: 5000
  # ```
  #
  # With environment variables, you may override option kyes in the
  # configuration file and default values. The name of environment variable
  # must be the key name with a prefix `YTDL_`, and in all upper case.
  #
  # Example to override `redis_port`:
  #
  # /usr/bin/env YTDL_REDIS_PORT=12345
  class ConfigLoader
    VALID_OPTION = {
      "download_dir" => { type: String, required: true },
      "redis_address" => { type: String, default: "127.0.0.1", required: false },
      "redis_dbfilename" => { type: String, default: "dump.rdb", required: false },
      "redis_port" => { type: Integer, default: 6379, required: false }
    }.freeze

    def initialize; end

    def required_keys
      VALID_OPTION.select { |_k, v| v[:required] }.keys
    end

    def validate_missing_key(config)
      required_keys.each do |k|
        raise ArgumentError, format("Key `%<key>s` is required, but missing", key: k) unless config.key? k
      end
      config
    end

    def validate_unknown_key(config)
      config.each_key do |k|
        raise ArgumentError, format("Unknown option: `%<key>s`", key: k) unless VALID_OPTION.keys.include? k
      end
      config
    end

    def validate_type(config)
      config.each do |k, v|
        unless v.is_a? VALID_OPTION[k][:type]
          raise ArgumentError,
                format("Key `%<key>s` must be %<type>s, but `%<actual>s`", key: k, type: VALID_OPTION[k], actual: v)
        end
      end
      config
    end

    def validate(config)
      validate_missing_key(config)
      validate_unknown_key(config)
      validate_type(config)
      config
    end

    def read_file(path)
      File.read(path)
    rescue StandardError => e
      warn format("Cannot read configuration file `%<path>s`", path: Pathname.pwd + path)
      raise e
    end

    def read_erb(config)
      ERB.new(config).result
    end

    def read_yaml(arg)
      result = YAML.safe_load(arg)
      # XXX when input is empty, safe_load returns false
      raise ArgumentError, "empty YAML" unless result

      result
    end

    def default_option
      default = {}
      VALID_OPTION.each do |k, v|
        raise format("BUG: Key `%<key>s` is required but has `:default`", key: k) if v[:required] && v[:default]

        if !v[:required] && !v.key?(:default)
          raise format("BUG: Key `%<key>s` is not required but has no `:default`",
                       key: k)
        end

        default[k] = v[:default] if v.key?(:default)
      end
      default
    end

    def merge_default(config)
      default_option.merge(config)
    end

    def validate_key_has_valid_type_in_env(key)
      env_key = "YTDL_#{key.upcase}"
      return unless ENV.key?(env_key)

      if VALID_OPTION[key][:type] == Integer && !ENV[env_key].match(/^\d+$/)
        raise ArgumentError, format("`%<key>s` in ENV is not Integer: `%<value>s`", key: env_key, value: ENV[env_key])
      end

      true
    end

    def override_with_env(config)
      config.each_key do |k|
        env_key = "YTDL_#{k.upcase}"
        next unless ENV.key?(env_key)

        validate_key_has_valid_type_in_env(k)
        config[k] = VALID_OPTION[k][:type] == Integer ? ENV[env_key].to_i : ENV[env_key]
      end
      config
    end

    def load_file(path)
      config = read_file(path)
      config = read_erb(config)
      config = read_yaml(config)
      config = merge_default(config)
      config = override_with_env(config)
      validate(config)
    end
  end
end
