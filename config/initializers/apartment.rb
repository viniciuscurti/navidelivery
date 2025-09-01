Apartment.configure do |config|
  config.excluded_models = %w{ Account }
  config.tenant_names = lambda do
    begin
      # Evita tentativa de conexão em fases como assets:precompile sem DB
      next [] if ENV["RAILS_GROUPS"]&.include?("assets") || ENV["DISABLE_DB"] == "1"
      # Verifica se conexão pode ser estabelecida
      if defined?(ActiveRecord::Base)
        # Tenta criar conexão se ainda não criada
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          if conn.respond_to?(:data_source_exists?) && conn.data_source_exists?("accounts")
            Account.pluck(:subdomain)
          else
            []
          end
        end
      else
        []
      end
    rescue StandardError
      []
    end
  end
end
