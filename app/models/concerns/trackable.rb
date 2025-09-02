# Concern para padronizar tracking de entidades
module Trackable
  extend ActiveSupport::Concern

  included do
    validates :status, inclusion: { in: self::STATUSES }

    scope :active, -> { where.not(status: [:delivered, :canceled]) }
    scope :today, -> { where(created_at: Date.current.all_day) }

    after_update :broadcast_status_change, if: :saved_change_to_status?
  end

  class_methods do
    def status_enum
      self::STATUSES.index_with(&:to_sym)
    end
  end

  private

  def broadcast_status_change
    # Override in including classes
  end
end

