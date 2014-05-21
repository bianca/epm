require 'spec_helper'

describe "Users" do

  include Warden::Test::Helpers
  before :all do
    @participant = create :participant, fname: 'Randomname', lname: 'Lastylast'
    @coordinator = create :coordinator
    @admin = create :admin, fname: 'Admiral', lname: 'Adminy'
  end
  after :each do
    Warden.test_reset!
  end

  context "user list" do

    it "allows admins to access user list" do
      login_as @admin
      visit root_path
      click_link 'Users'
      expect(current_path).to eq users_path
      expect(page).to have_content @admin.display_name
    end

    it "does not allow non-admins to access user list" do
      [@participant, @coordinator].each do |user|
        login_as user
        visit root_path
        expect(page).not_to have_content 'Users'
        visit users_path
        expect(current_path).not_to eq users_path
        expect(page).to have_content 'Sorry'
        logout
      end
    end

    it "shows user search results" do
      create :user, fname: 'Joe', email: 'joe@example.com'
      create :user, fname: 'Jack', email: 'jack@example.com'
      login_as @admin
      visit users_path
      fill_in 'q', with: 'joe'
      click_button 'Search'
      expect(current_path).to eq users_path
      expect(page).to have_content 'Joe'
      expect(page).not_to have_content 'Jack'
    end

    it "shows users with a particular role" do
      login_as @admin
      visit users_path
      expect(page).to have_content @participant.display_name
      select 'Admins', from: :show_only
      click_button 'Search'
      expect(find('option[selected]').text).to eq 'Admins'
      expect(page).to have_content @admin.display_name
      expect(page).not_to have_content @participant.display_name
      select 'Participants', from: :show_only
      click_button 'Search'
      expect(find('option[selected]').text).to eq 'Participants'
      expect(page).not_to have_content @admin.display_name
      expect(page).to have_content @participant.display_name
    end

    it "exports user list to csv" do
      login_as @admin
      visit users_path
      click_link 'Export'
      csv = CSV.parse(source) # using source as page has normalized the whitespace (thus having no newlines)
      expect(csv.length).to eq (User.count + 1)
      ['id', 'first name', 'last name', 'email', 'phone number', 'address', 'roles', 'events attended', 'joined'].each do |field|
        expect(csv.first).to include field
      end
      expect(page).to have_content @admin.email
    end

    it "shows 20 users per page" do
      25.times { create :user }
      login_as @admin
      visit users_path
      expect(all('.user').length).to eq 20
      expect(page).not_to have_link 'Prev'
      all('.next a').first.click
      expect(page).to have_link 'Prev'
      expect(page).not_to have_link 'Next'
      expect(all('.user').length).to eq (User.count - 20)
    end

  end

  it "allows admins to edit any profile" do
    u = create :user
    login_as @admin
    visit user_path u
    click_link 'Edit'
    fill_in 'E-mail Address', with: 'whatever@some-site.com'
    click_button 'Save'
    expect(current_path).to eq user_path u
    expect(page).to have_content 'whatever@some-site.com'
  end

  context "profile" do

    context "access and crud" do

      before :each do
        login_as @participant
      end

      it "has a profile page" do
        visit root_path
        click_link 'My Profile'
        expect(current_path).to eq user_path @participant
        expect(page).to have_content @participant.display_name
      end

      it "can access profile page from /me" do
        visit me_path
        expect(current_path).to eq user_path @participant
      end

      it "edits own profile" do
        visit user_path @participant
        click_link 'Edit'
        expect(current_path).to eq edit_user_path @participant
        fill_in 'user_fname', with: 'Joe'
        fill_in 'user_lname', with: 'Smith'
        click_button 'Save'
        expect(current_path).to eq user_path @participant
        expect(page).to have_content 'Joe Smith'
        end

      it "prevents editing another's profile" do
        other_user = create :user
        visit user_path(other_user)
        expect(page).not_to have_content 'Edit'
        visit edit_user_path(other_user)
        expect(current_path).to eq root_path
        expect(page).to have_content 'Sorry'
      end

      it "cancels editing one's profile" do
        visit user_path @participant
        click_link 'Edit'
        fill_in 'user_fname', with: 'Joe'
        click_button 'Cancel'
        expect(current_path).to eq user_path @participant
        expect(page).not_to have_content 'Joe'
      end

      it "sets one's wards" do
        create :ward, name: 'ward one'
        create :ward, name: 'ward two'
        visit edit_user_path @participant
        check 'ward one'
        click_button 'Save'
        expect(page).to have_content 'ward one'
        expect(page).not_to have_content 'ward two'
      end

    end

    context "profile permissions" do

      before :all do
        @u = create :full_user, address: '123 Fake Street, City' # set address without newlines so we don't have to worry about matching that
        @u.roles.create name: :participant
        @e = create :participatable_event
        @e.attend @u
        @e.update(start: 1.month.ago, finish: 1.month.ago + 1.hour)
      end

      it "shows profile with all contact info and attendance history to self" do
        login_as @u
        visit user_path @u
        expect(current_path).to eq user_path @u
        expect(page).to have_content @u.display_name
        expect(page).to have_link @u.email
        expect(page).to have_link @u.phone
        expect(page).to have_content @u.address
        expect(page).to have_link @e.display_name
      end

      it "shows profile with contact info and attendance history to admins" do
        login_as create :admin
        visit user_path @u
        expect(current_path).to eq user_path @u
        expect(page).to have_content @u.display_name
        expect(page).to have_link @u.email
        expect(page).to have_link @u.phone
        expect(page).to have_content @u.address
        expect(page).to have_link @e.display_name
      end

      it "shows profile with contact info and attendance history to admins" do
        login_as create :admin
        visit user_path @u
        expect(current_path).to eq user_path @u
        expect(page).to have_content @u.display_name
        expect(page).to have_link @u.email
        expect(page).to have_link @u.phone
        expect(page).to have_content @u.address
        expect(page).to have_link @e.display_name
      end

      it "does not show other user profiles to participants" do
        login_as create :participant
        visit user_path @u
        expect(current_path).not_to eq user_path @u
        expect(page).to have_content 'Sorry'
      end

    end

    context "filling out" do

      it "sends new user to edit profile" do
        pass = Faker::Internet.password
        u = create :user, password: pass
        visit new_user_session_path
        fill_in 'E-mail', with: u.email
        fill_in 'Password', with: pass
        click_button 'Sign in'
        expect(current_path).to eq edit_user_path u
      end

      it "does not send new user to edit profile when already filled out" do
        pass = Faker::Internet.password
        u = create :full_user, password: pass
        visit new_user_session_path
        fill_in 'E-mail', with: u.email
        fill_in 'Password', with: pass
        click_button 'Sign in'
        expect(current_path).not_to eq edit_user_path u
      end

      it "does not send a non-new user to edit their profile even when not filled out" do
        pass = Faker::Internet.password
        u = create :full_user, password: pass, sign_in_count: 10 # fake that they've signed in a lot
        visit new_user_session_path
        fill_in 'E-mail', with: u.email
        fill_in 'Password', with: pass
        click_button 'Sign in'
        expect(current_path).not_to eq edit_user_path u
      end

    end

  end

  context "roles" do

    it "allows an admin to add a role" do
      participant = create :participant # don't pollute @participant
      login_as @admin
      visit user_path participant
      select 'Coordinator', from: 'role_name'
      click_button 'Add'
      expect(current_path).to eq user_path participant
      expect(page).to have_content 'Role added'
      expect(participant.reload.has_role? :coordinator).to be_true
    end

    it "prevents non-admins from adding a role" do
      [@participant, @coordinator].each do |user|
        login_as user
        visit user_path @participant
        expect(page).not_to have_button 'Add'
        logout
      end
    end

    it "does not show role adding form if user has all roles" do
      user = create :participant
      user.roles.create name: :coordinator
      user.roles.create name: :admin
      login_as @admin
      visit user_path user
      expect(page).not_to have_button 'Add'
    end

    it "allows an admin to remove a role" do
      participant = create :participant # don't pollute @participant
      e = create :participatable_event
      e.attend participant
      login_as @admin
      visit user_path participant
      click_button 'x' # user has only one role, so this is the right delete link
      expect(current_path).to eq user_path participant
      expect(page).to have_content 'Role removed'
      within '#roles' do
        expect(page).to have_content 'None'
      end
      visit event_path e
      expect(page).not_to have_link participant.display_name
    end

    it "prevents non-admins from removing others' roles" do
      users = [@participant, @coordinator]
      users.each_with_index do |user, i|
        login_as user
        visit user_path users.reverse[i]
        expect(page).not_to have_button 'Add'
        logout
      end
    end

    it "allows deactivating oneself" do
      participant = create :participant
      e = create :participatable_event
      e.attend participant
      login_as participant
      visit user_path participant
      click_link 'Deactivate'
      expect(current_path).to eq user_path participant
      expect(page).to have_content 'deactivated'
      within '#roles' do
        expect(page).not_to have_content 'Participant'
      end
      visit event_path e
      expect(page).not_to have_link participant.display_name
    end

    it "does not allow deactivating another" do
      login_as @admin
      visit user_path @participant
      expect(page).not_to have_link 'Deactivate'
    end

    it "shows a message to users with no roles" do
      p = create :participant
      login_as p
      visit root_path
      expect(page).not_to have_content 'has been deactivated'
      p.roles.destroy_all
      visit root_path
      expect(page).to have_content 'has been deactivated'
    end

  end

end

# the below tests are separated from above, as the js: true tests were interfering with other tests above and causing them to fail
describe "user map" do

  include Warden::Test::Helpers

  after :each do
    Warden.test_reset!
  end

  it "shows a map to admin", js: true do
    User.participants.geocoded.destroy_all # todo: why this is needed here
    9.times { create :participant, lat: Faker::Address.latitude, lng: Faker::Address.longitude }
    login_as create :admin
    visit users_path
    click_link 'Map'
    expect(current_path).to eq map_users_path
    expect(map_points).to eq 0 # need at least 10 people to show any
    create :participant, lat: Faker::Address.latitude, lng: Faker::Address.longitude
    visit map_users_path
    expect(map_points).to eq 10
  end

  it "does not show a map to participants" do
    login_as create :participant
    visit map_users_path
    expect(current_path).not_to eq map_users_path
    expect(page).to have_content 'Sorry'
  end

  it "does not show a map to coordinators" do
    login_as create :coordinator
    visit map_users_path
    expect(current_path).not_to eq map_users_path
    expect(page).to have_content 'Sorry'
  end

end