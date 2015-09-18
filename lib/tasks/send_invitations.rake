task :send_invitations => :environment do

  Invitation.where("send_by < ?", Time.zone.now).find_each do |invitation|
    possible_events = Event.where id: invitation.event_id
    if possible_events.any?
      e = possible_events.first
      if e.full? && !e.can_have_participants?
        Invitation.where(event_id: e.id).destroy_all
      elsif e.approved?
        eus = e.event_users.where user_id: invitation.user_id
        if eus.any?
          eu = eus.first
          EventMailer.invite(invitation.event, invitation.user).deliver if eu.invited?
        end
      end
    end
    invitation.destroy
  end

end