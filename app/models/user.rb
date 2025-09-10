class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  belongs_to :account, optional: true
  has_many :deliveries, dependent: :destroy, foreign_key: :user_id
  has_many :location_pings, through: :deliveries

  # Secure token for API authentication
  has_secure_token :api_token

  # Enums
  enum role: {
    user: 0,
    store_manager: 1,
    courier: 2,
    admin: 3,
    super_admin: 4
  }, _default: :user

  enum status: {
    active: 0,
    inactive: 1,
    suspended: 2
  }, _default: :active

  # Validations
  validates :first_name, :last_name, presence: true
  validates :phone, presence: true, format: { with: /\A\+?[1-9]\d{1,14}\z/ }
  validates :role, presence: true
  validates :status, presence: true
  validates :account, presence: true, unless: :super_admin?

  # Scopes
  scope :by_account, ->(account) { where(account: account) }
  scope :by_role, ->(role) { where(role: role) }
  scope :active_users, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_create :generate_api_token
  before_validation :normalize_phone
  after_create :send_welcome_email, if: :persisted?

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def active?
    status == 'active'
  end

  def can_manage_account?(target_account)
    return true if super_admin?
    return false if account != target_account

    admin? || store_manager?
  end

  def can_access_delivery?(delivery)
    return true if super_admin?
    return false if account != delivery.account

    case role
    when 'admin'
      true
    when 'store_manager'
      delivery.store.account == account
    when 'courier'
      delivery.courier_id == id
    else
      false
    end
  end

  def regenerate_api_token!
    regenerate_api_token
    save!
  end

  # Class methods
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = auth.info.first_name || auth.info.name&.split&.first
      user.last_name = auth.info.last_name || auth.info.name&.split&.last
      user.provider = auth.provider
      user.uid = auth.uid
    end
  end

  def self.search(query)
    return none if query.blank?

    where(
      "first_name ILIKE :query OR last_name ILIKE :query OR email ILIKE :query",
      query: "%#{query}%"
    )
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32) if api_token.blank?
  end

  def normalize_phone
    return unless phone.present?

    # Remove all non-digit characters except +
    self.phone = phone.gsub(/[^\d+]/, '')

    # Add country code if not present (assuming Brazil +55)
    self.phone = "+55#{phone}" if phone.match?(/\A\d{10,11}\z/)
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end
end
