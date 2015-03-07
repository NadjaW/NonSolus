class User < ActiveRecord::Base

  has_and_belongs_to_many :activities
  validates :first_name, :email, :username, :workforceid, presence: true
  #validates :first_name, :last_name, :email, :username, :workforceid, presence: true
  scope :subscribers, -> { where(subscriber: true) }

  class << self

    def find_or_create_for_saml(data)
      user = User.where('lower(username) = ?', data[:username].downcase).first || User.new
      user.update_attributes!(data)
      user
    end

  end

end

