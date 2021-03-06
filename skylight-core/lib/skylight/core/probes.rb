module Skylight::Core
  # @api private
  module Probes

    @@available = nil

    def self.available
      unless @@available
        root = File.expand_path("../probes", __FILE__)
        @@available = {}
        Dir["#{root}/*.rb"].each do |f|
          name = File.basename(f, '.rb')
          @@available[name] = "skylight/core/probes/#{name}"
        end
      end
      @@available
    end

    def self.probe(*probes)
      unknown = probes.map(&:to_s) - available.keys
      unless unknown.empty?
        raise ArgumentError, "unknown probes: #{unknown.join(', ')}"
      end

      probes.each do |p|
        require available[p.to_s]
      end
    end

    class ProbeRegistration
      attr_reader :klass_name, :require_paths, :probe

      def initialize(klass_name, require_paths, probe)
        @klass_name = klass_name
        @require_paths = Array(require_paths)
        @probe = probe
      end

      def install
        probe.install
      end
    end

    def self.require_hooks
      @require_hooks ||= {}
    end

    def self.installed
      @installed ||= {}
    end

    def self.is_available?(klass_name)
      !!Util::Inflector.safe_constantize(klass_name)
    end

    def self.register(*args)
      registration = ProbeRegistration.new(*args)

      if is_available?(registration.klass_name)
        installed[registration.klass_name] ||= []
        installed[registration.klass_name] << registration
        registration.install
      else
        register_require_hook(registration)
      end
    end

    def self.require_hook(require_path)
      registrations = lookup_by_require_path(require_path)
      return unless registrations

      registrations.each do |registration|
        # Double check constant is available
        if is_available?(registration.klass_name)
          installed[registration.klass_name] ||= []
          installed[registration.klass_name] << registration
          registration.install

          # Don't need this to be called again
          unregister_require_hook(registration)
        end
      end
    end

    def self.register_require_hook(registration)
      registration.require_paths.each do |p|
        require_hooks[p] ||= []
        require_hooks[p] << registration
      end
    end

    def self.unregister_require_hook(registration)
      registration.require_paths.each do |p|
        require_hooks[p].delete(registration)
        require_hooks.delete(p) if require_hook[p].empty?
      end
    end

    def self.lookup_by_require_path(require_path)
      require_hooks[require_path]
    end
  end
end

# Allow hooking require
# @api private
module ::Kernel
  alias require_without_sk require

  def require(name)
    ret = require_without_sk(name)

    begin
      Skylight::Core::Probes.require_hook(name)
    rescue Exception
      # FIXME: Log these errors
    end

    ret
  rescue LoadError
    # Support pre-2.0 style requires
    if name =~ %r{^skylight/probes/(.+)}
      warn "[DEPRECATION] Requiring Skylight probes by path is deprecated. Use `Skylight.probe(:#{$1})` instead."
      require "skylight/core/probes/#{$1}"
    else
      raise
    end
  end
end
