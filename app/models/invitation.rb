class Invitation < ActiveRecord::Base

  belongs_to :user
  belongs_to :event

  validates :user_id, :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event }

  before_save do |invitation|
    invitation.send_by = Time.zone.now unless invitation.send_by.present?
  end

end