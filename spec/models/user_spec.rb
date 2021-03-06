require 'spec_helper'

describe User do

  context "attributes" do

    # all fields should be stripped, this just tests two (excessive to check them all)
    context "normalizing attributes" do

      it "strips the first name" do
        expect(create(:user, fname: "  Joe\n").fname).to eq 'Joe'
      end

      it "nullifies empty address" do
        expect(create(:user, address: " \n").address).to be_nil
      end

    end

    context "validity" do

      it "has a valid factory" do
        expect(create(:user)).to be_valid
      end

      it "is invalid without an email" do
        expect(build(:user, email: nil)).not_to be_valid
      end

      it "is invalid without a password" do
        expect(build(:user, password: nil)).not_to be_valid
      end

      it "is invalid with an overly short password" do
        expect(build(:user, password: "foo")).not_to be_valid
      end

      it "is invalid with an incorrect password confirmation" do
        expect(build(:user, password: "1234567", password_confirmation: "1234568")).not_to be_valid
      end

      it "does not allow multiple users with the same email, case insensitively" do
        user1 = build :user
        user1.email = user1.email.upcase
        user1.save
        expect(build(:user, email: user1.email.downcase)).not_to be_valid
      end

      it "is valid with a latitude in range" do
        expect(build :event, lat: 40, lng: -80).to be_valid
      end

      it "is invalid with a latitude out of range" do
        expect(build :event, lat: 3000, lng: -80).not_to be_valid
      end

    end

    context "geocoding" do

      it "geocodes an address" do
        e = build :user, address: '1600 Pennsylvania Avenue, Washington, DC'
        e.valid? # triggers geocoding
        expect(e.lat).to be_within(1).of(38)
        expect(e.lng).to be_within(1).of(-77)
      end

      it "does not override given coordinates" do
        e = build :user, address: '1600 Pennsylvania Avenue, Washington, DC', lat: 40, lng: -75
        e.valid? # triggers geocoding
        expect(e.lat).to eq 40
        expect(e.lng).to eq -75
      end

    end

    it "has an avatar which is a url" do
      expect(build(:user).avatar).to match URI::regexp(%w(http https))
    end

    it "returns the number of events the user didn't show up to" do
      p = create :participant
      p2 = create :participant
      e1 = create :participatable_event
      e1.event_users.create user: p, status: :no_show
      e2 = create :participatable_event, coordinator: e1.coordinator
      e2.event_users.create user: p, status: :no_show
      e3 = create :participatable_event, coordinator: e1.coordinator
      e3.event_users.create user: p, status: :attended
      e3.event_users.create user: p2, status: :no_show
      expect(p.no_show_count).to eq 2
      expect(p2.no_show_count).to eq 1
    end

    it "returns how many events a user has participated in" do
      p = create :participant
      e = create :participatable_event
      eu = e.attend p
      expect(p.num_participated_events).to eq 0
      e.take_attendance [eu.id]
      expect(p.reload.num_participated_events).to eq 1
      e.take_attendance [] # i.e. indicate that the user did *not* attend
      expect(p.reload.num_participated_events).to eq 0
    end

  end

  context "roles" do

    it "ensures the first user is an admin but others are participants" do
      User.delete_all # todo: figure out why this is needed... should be handled by database cleaner
      expect(create(:user).roles.where(name: Role.names[:admin]).count).to eq 1
      expect(create(:user).roles.where(name: Role.names[:participant]).count).to eq 1
    end

    it "creates a user with the specified role" do
      role_name = :coordinator
      expect(create(:user, roles_attributes: [name: role_name]).roles.where(name: Role.names[role_name]).count).to eq 1
    end

    it "responds properly to has_role?" do
      p = create :participant
      expect(p.has_role? :participant).to be_true
      expect(p.has_role? :coordinator).to be_false
      expect(p.has_role? :admin).to be_false
      p.roles.create name: :coordinator
      expect(p.has_role? :participant).to be_true
      expect(p.has_role? :coordinator).to be_true
      expect(p.has_role? :admin).to be_false
    end

    it "response properly to has_any_role?" do
      p = create :participant
      expect(p.has_any_role? :participant).to be_true
      expect(p.has_any_role? :coordinator).to be_false
      expect(p.has_any_role? :participant, :coordinator).to be_true
      expect(p.has_any_role? :participant, :coordinator, :admin).to be_true
      expect(p.has_any_role? :coordinator, :admin).to be_false
      expect(p.has_any_role? :admin).to be_false
      p.roles.create name: :coordinator
      expect(p.has_any_role? :participant).to be_true
      expect(p.has_any_role? :coordinator).to be_true
      expect(p.has_any_role? :participant, :coordinator).to be_true
      expect(p.has_any_role? :participant, :coordinator, :admin).to be_true
      expect(p.has_any_role? :coordinator, :admin).to be_true
      expect(p.has_any_role? :admin).to be_false
    end

  end

  context "multiple users" do

    before :each do
      User.delete_all # todo: figure out why this is needed... should be handled by database cleaner
    end

    it "orders users by name" do
      b = create :user, lname: 'b'
      a = create :user, lname: 'a'
      cz = create :user, lname: 'c', fname: 'z'
      ca = create :user, lname: 'c', fname: 'a'
      expect(User.by_name).to eq [a, b, ca, cz]
    end

    it "lists no show users, by date of most recent no show" do
      e = create :participatable_event
      no_show = create :participant
      no_show.event_users.create event: e, status: :no_show
      later_no_show = create :participant
      later_no_show.event_users.create event: e, status: :no_show
      attended = create :participant
      attended.event_users.create event: e, status: :attended
      expect(User.no_shows).to eq [later_no_show, no_show]
    end

    it "lists users that have coordinates" do
      w_coords = create :user, lat: 50, lng: 50
      wo_coords = create :user, lat: nil, lng: nil
      expect(User.geocoded).to eq [w_coords]
    end

    it "lists users according to role" do
      a = create :admin
      c = create :coordinator
      p1 = create :participant
      p1.roles.create name: :coordinator
      p2 = create :participant
      p3 = create :participant
      bad_user = create :participant
      bad_user.roles.destroy_all
      participants = User.participants
      expect(participants.length).to eq 3
      expect(participants).to include p1
      expect(participants).to include p2
      expect(participants).to include p3
      coordinators = User.coordinators
      expect(coordinators.length).to eq 2
      expect(coordinators).to include c
      expect(coordinators).to include p1
      admins = User.admins
      expect(admins.length).to eq 1
      expect(admins.first).to eq a
      nobodies = User.roleless
      expect(nobodies).to eq [bad_user]
    end

    it "searches for users" do
      u1 = create :user, fname: 'Joe', lname: 'Smith', email: 'joe_smith@example.com'
      u2 = create :user, fname: 'Sally', email: 'sally_smith@example.com'
      u3 = create :user, fname: 'Bob', lname: 'Dole', email: 'blabla@example.com'
      u4 = create :user, fname: 'Bobby', lname: 'Blacksmith', email: 'whatever@example.com'
      smiths = User.search 'smith' # checks that it looks in first and last name and email fields
      expect(smiths.length).to eq 3
      expect(smiths).to include u1
      expect(smiths).to include u2
      expect(smiths).to include u4
      bobs = User.search 'bob' # checks for case sensitivity
      expect(bobs.length).to eq 2
      expect(bobs).to include u3
      expect(bobs).to include u4
      expect(User.search('Jack').length).to eq 0
    end

    it "lists coordinators not taking attendance" do
      p = create :participant
      # c_takes always take attendance
      c_takes = create :coordinator
      # not using :participatable_past_event because we want to ensure they're at least 3 days old, i.e. threshold for when attendance should be taken by
      e1 = create :participatable_event, start: 1.month.ago, coordinator: c_takes
      e1.event_users.create user: p, status: :attended
      # c_verybad never takes attendance
      c_verybad = create :coordinator
      e2 = create :participatable_event, start: 1.month.ago, coordinator: c_verybad
      e2.event_users.create user: p, status: :attending
      e3 = create :participatable_event, start: 1.month.ago, coordinator: c_verybad
      e3.event_users.create user: p, status: :attending
      # c_bad sometimes takes attendance
      c_bad = create :coordinator
      e4 = create :participatable_event, start: 1.month.ago, coordinator: c_bad
      e4.event_users.create user: p, status: :attended
      e5 = create :participatable_event, start: 1.month.ago, coordinator: c_bad
      e5.event_users.create user: p, status: :attending
      # expect the two bad coordinators to be listed, ordered by worst coordinator first
      bad_coordinators = User.coordinators_not_taking_attendance
      expect(bad_coordinators.index c_verybad).to be < bad_coordinators.index(c_bad)
    end

    it "lists users not involved in an event" do
      e = create :participatable_event
      p_attending = create :participant
      e.attend p_attending
      p_invited = create :participant
      e.event_users.create user: p_invited, status: :invited
      p1 = create :participant
      p2 = create :participant
      people = User.not_involved_in e
      expect(people).to include p1
      expect(people).to include p2
      expect(people).not_to include p_attending
      expect(people).not_to include p_invited
    end

    it "lists users interested in a particular ward" do
      w1 = create :ward
      w2 = create :ward
      u1 = create :user
      u1.user_wards.create ward: w1
      u2 = create :user
      u2.user_wards.create ward: w2
      expect(User.interested_in_ward w1).to eq [u1]
    end

    it "lists users who can be invited to an event" do
      # ie users who are participants, interested in the event's ward, who aren't already involved
      e = create :participatable_event, ward: create(:ward)
      u = create :user
      p = create :participant
      p_interested = create :participant
      p_interested.user_wards.create ward: e.ward
      p_attending = create :participant
      p_attending.user_wards.create ward: e.ward
      e.attend p_attending
      expect(User.invitable_to e).to eq [p_interested]
    end

    it "lists no users who can be invited to an event with no ward" do
      expect(User.invitable_to(create(:participatable_event)).length).to eq 0
    end

  end

  context "events" do

    it "lists events a user is coordinating" do
      u = create :coordinator
      create :event, coordinator: u
      create :event, coordinator: u
      create :event # event 3, not coordinating
      expect(u.coordinating_events.length).to eq 2
    end

    it "lists events a user is participating in" do
      p = create :participant
      c = create :coordinator
      e_not_participating = create :participatable_event, coordinator: c
      e_participating = create :participatable_event, coordinator: c
      e_participating.attend p
      e_cancelled = create :participatable_event, coordinator: c
      e_cancelled.attend p
      e_cancelled.update status: :cancelled
      expect(p.participating_events).to eq [e_participating]
    end

    it "lists events a user is involved with" do
      # user is a coordinator and participant
      u = create :coordinator
      u.roles.create name: :participant
      c = create :coordinator
      # 1 - is coordinator
      e_coordinating = create :participatable_event, coordinator: u
      # 2 - is a participant
      e_participating = create :participatable_event, coordinator: c
      e_participating.attend u
      # 3 - is a participant
      e_participating_past = create :participatable_event, coordinator: c
      e_participating_past.attend u
      e_participating_past.update(start: 1.month.ago, duration: 1.hour)
      # not counted - attending a cancelled event
      e_cancelled = create :participatable_event, coordinator: c
      e_cancelled.attend u
      e_cancelled.update(status: Event.statuses[:cancelled])
      # not counted - on the waitlist for an event
      e_waitlisted = create :participatable_event, max: 1, coordinator: c
      e_waitlisted.attend create :participant
      e_waitlisted.attend u
      # not counted - not participating in this event
      e_not_attending = create :participatable_event, coordinator: c
      expect(u.events.length).to eq 3
      expect(u.events).to include e_coordinating
      expect(u.events).to include e_participating
      expect(u.events).to include e_participating_past
    end

    it "lists events a user might be attending" do
      # todo: also test for event_user status :requested
      p1 = create :participant
      p2 = create :participant
      c = create :coordinator
      e_attending = create :participatable_event, max: 1, coordinator: c
      e_attending.attend p1
      e_attending.attend p2 # p2 waitlisted
      e_waitlisted = create :participatable_event, max: 1, coordinator: c
      e_waitlisted.attend p2
      e_waitlisted.attend p1
      e_waitlisted_past = create :participatable_event, max: 1, coordinator: c
      e_waitlisted_past.attend p2
      e_waitlisted_past.attend p1
      e_waitlisted_past.update(start: 1.month.ago, duration: 1.hour)
      e_cancelled = create :participatable_event, max: 1, coordinator: c
      e_cancelled.attend p2
      e_cancelled.attend p1
      e_cancelled.update(status: Event.statuses[:cancelled])
      expect(p1.potential_events).to eq [e_waitlisted]
    end

    it "lists upcoming events the user has been invited to" do
      p1 = create :participant
      p2 = create :participant
      c = create :coordinator
      e_attending = create :participatable_event, coordinator: c
      e_attending.attend p1
      e_invited = create :participatable_event, coordinator: c
      e_invited.event_users.create user: p1, status: :invited
      e_cancelled = create :participatable_event, coordinator: c
      e_cancelled.event_users.create user: p1, status: :invited
      e_cancelled.update status: :cancelled
      e_p2_invited = create :participatable_event, coordinator: c
      e_p2_invited.event_users.create user: p2, status: :invited
      expect(p1.open_invites).to eq [e_invited]
    end

  end

  context "mailing list" do

    it "subscribes a user to the mailing list" do
      u = build :user
      # note: the api is currently disabled for non-production, in test it will always return true
      # todo: http://robots.thoughtbot.com/how-to-stub-external-services-in-tests
      expect(u.add_to_mailing_list).to be_true
    end

    it "does not subscribe a user with no email address to the mailing list" do
      u = build :user, email: nil
      expect(u.add_to_mailing_list).to be_false
    end

  end

end