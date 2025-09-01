ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Patch precoce: garantir que nenhuma String chegue ao ponto de klass.new(app,...)
begin
  require 'rack'
  module RackBuilderStringMiddlewarePatch
    def use(middleware, *args, &block)
      if middleware.is_a?(String)
        warn "[rack_use_patch] Middleware String detectado: '#{middleware}' — tentando constantizar"
        begin
          const = middleware.split('::').inject(Object) { |mod, name| mod.const_get(name) }
          if const.is_a?(Class)
            middleware = const
            warn "[rack_use_patch] Sucesso: '#{middleware}' convertido para classe #{const}"
          else
            warn "[rack_use_patch] Objeto obtido nao eh Classe: #{const.inspect}"
          end
        rescue StandardError => e
          warn "[rack_use_patch] Falha constantizando '#{middleware}': #{e.class}: #{e.message}"
        end
      end
      super(middleware, *args, &block)
    end
  end
  Rack::Builder.prepend(RackBuilderStringMiddlewarePatch) unless Rack::Builder.ancestors.include?(RackBuilderStringMiddlewarePatch)
rescue LoadError
  # Rack nao carregado ainda; ignorar
end
