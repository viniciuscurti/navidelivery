require 'interactor'

class BaseInteractor
  include Interactor

  # Métodos utilitários comuns para todos os interactors
  def fail_with_error!(error)
    context.fail!(error: Array(error).map(&:to_s))
  end

  # Exemplo: validação de presença de parâmetros obrigatórios
  def require_params!(*keys)
    missing = keys.select { |k| context.send(k).nil? }
    fail_with_error!("Parâmetro obrigatório ausente: #{missing.join(', ')}") unless missing.empty?
  end
end

