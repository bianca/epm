require 'spec_helper'

describe "Authentication" do

  it "signs up a new user" do
    visit new_user_registration_path
    pass = Faker::Internet.password
    u = build :user, password: pass
    fill_in 'E-mail Address', with: u.email
    fill_in 'user_password', with: pass
    fill_in 'user_password_confirmation', with: pass
    fill_in 'user_fname', with: u.fname
    fill_in 'user_lname', with: u.lname
    fill_in 'Phone', with: u.phone
    check 'I want to participate in NFFTT picks'
    check 'I have read and agree to the above release of liability'
    expect{ click_button 'Sign up' }.to change{ActionMailer::Base.deliveries.size}.by 1
    user = User.last
    expect(last_email.to).to eq [user.email]
    expect(last_email.from).to eq ['no-reply@example.com']
    expect(current_path).to eq new_user_session_path
    expect(page).to have_content 'Check your inbox and spam folder for a confirmation email'
  end

  it "signs up a new user for adding trees" do
    visit new_user_registration_path
    pass = Faker::Internet.password
    u = build :user, password: pass
    fill_in 'E-mail Address', with: u.email
    fill_in 'user_password', with: pass
    fill_in 'user_password_confirmation', with: pass
    fill_in 'user_fname', with: u.fname
    fill_in 'user_lname', with: u.lname
    fill_in 'Phone', with: u.phone
    check "I want to add trees to NFFTT's tree database"
    expect{ click_button 'Sign up' }.to change{ActionMailer::Base.deliveries.size}.by 1
    user = User.last
    expect(last_email.to).to eq [user.email]
    expect(last_email.from).to eq ['no-reply@example.com']
    expect(current_path).to eq new_user_session_path
    expect(page).to have_content 'Check your inbox and spam folder for a confirmation email'
  end

  it "fails to sign up a new user that doesn't want to add trees or participate in picks" do
    visit new_user_registration_path
    pass = Faker::Internet.password
    u = build :user, password: pass
    fill_in 'E-mail Address', with: u.email
    fill_in 'user_password', with: pass
    fill_in 'user_password_confirmation', with: pass
    fill_in 'user_fname', with: u.fname
    fill_in 'user_lname', with: u.lname
    fill_in 'Phone', with: u.phone
    click_button 'Sign up'
    expect(current_path).to eq users_path
  end 

  it "fails to sign up an invalid user" do
    visit new_user_registration_path
    click_button 'Sign up'
    expect(current_path).to eq user_registration_path
    expect(page).to have_content 'Problem'
  end

  it "fails to sign up a user that wants to participate in picks without accepting the liability waiver" do
    visit root_path
    click_link "Sign up"
    pass = Faker::Internet.password
    u = build :full_user, password: pass
    check "user_participate_in_picks"
    fill_in 'user_email', with: u.email
    fill_in 'user_password', with: pass
    fill_in 'user_password_confirmation', with: pass
    fill_in 'user_fname', with: u.fname
    fill_in 'user_lname', with: u.lname
    fill_in 'Phone', with: u.phone
    click_button 'Sign up'
    expect(current_path).to eq user_registration_path
    expect(page).to have_content 'Problem'
  end

  it "signs up a user that wants to add trees only without accepting the liability waiver" do
    visit root_path
    click_link "Sign up"
    pass = Faker::Internet.password
    u = build :full_user, password: pass
    check "user_add_trees"
    fill_in 'user_email', with: u.email
    fill_in 'user_password', with: pass
    fill_in 'user_password_confirmation', with: pass
    fill_in 'user_fname', with: u.fname
    fill_in 'user_lname', with: u.lname
    fill_in 'Phone', with: u.phone
    click_button 'Sign up'
    expect(current_path).to eq new_user_session_path
    expect(page).not_to have_content 'Problem'
  end

  it "tells user that ward is not serviced", js: true do
    active_ward = create :ward
    inactive_ward = create :ward
    Configurable.active_wards = [active_ward.id]
    visit root_path
    click_link "Sign up"
    select inactive_ward.id, from: 'Home ward'
    expect(page).to have_content "We don't serve your ward yet"
    select active_ward.id, from: 'Home ward'
    expect(page).not_to have_content "We don't serve your ward yet"
  end

  it "logs in a user" do
    pass = Faker::Internet.password
    u = create :user, password: pass
    visit new_user_session_path
    fill_in 'E-mail', with: u.email
    fill_in 'Password', with: pass
    click_button 'Sign in'
    expect(page).to have_content 'Log out'
  end

  it "tells a user if their address isn't geocodable", js: true do
    visit root_path
    click_link "Sign up"
    fill_in 'Full Address', with: Faker::Lorem.sentences(rand 1..5).join(' ')
    find_field('Full Address').trigger('blur')
    Timeout.timeout(30) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
    expect(page).to have_content 'We couldnt find that address on a map.'
    fill_in 'Full Address', with: "#{Faker::Address.street_address}\n#{Faker::Address.city}, #{Faker::Address.country}"
    find_field('Full Address').trigger('blur')
    Timeout.timeout(30) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
    expect(page).not_to have_content 'We couldnt find that address on a map.'
  end

  it "fails to log in a user with bad credentials" do
    u = create :user
    visit new_user_session_path
    fill_in 'E-mail', with: u.email
    fill_in 'Password', with: Faker::Internet.password
    click_button 'Sign in'
    expect(page).to have_content 'Invalid'
  end

  it "sends a password reset email" do
    user = create(:user)
    visit new_user_session_path
    click_link 'Forgot your password?'
    fill_in 'E-mail', with: user.email
    expect { click_button 'Send' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.to).to eq [user.email]
    expect(last_email.from).to eq ['no-reply@example.com']
    expect(page).to have_content 'You will receive'
  end

  it "does not send a password reset email to non-users" do
    visit new_user_session_path
    click_link 'Forgot your password?'
    fill_in 'E-mail', with: Faker::Internet.email
    expect { click_button 'Send' }.not_to change{ActionMailer::Base.deliveries.size}
    expect(page).to have_content 'Problem'
  end

  it "resends a confirmation email upon request" do
    user = create :user, confirmed_at: nil
    visit new_user_session_path
    click_link "Didn't receive confirmation instructions?"
    fill_in 'E-mail', with: user.email
    expect { click_button 'Resend' }.to change{ActionMailer::Base.deliveries.size}.by 1
    expect(last_email.to).to eq [user.email]
    expect(last_email.from).to eq ['no-reply@example.com']
    expect(page).to have_content 'You will receive'
  end

  it "does not resends a confirmation email to non-users" do
    visit new_user_session_path
    click_link "Didn't receive confirmation instructions?"
    fill_in 'E-mail', with: Faker::Internet.email
    expect { click_button 'Resend' }.not_to change{ActionMailer::Base.deliveries.size}
    expect(page).to have_content 'Problem'
  end

  context "when logged in" do

    include Warden::Test::Helpers
    before :all do
      @original_password = 'some_password'
      @user = create :user, password: @original_password
    end
    before :each do
      login_as @user
    end
    after :each do
      Warden.test_reset!
    end

    it "logs out" do
      login_as @user # supposedly we also need scope: :user but this doesn't affect test results
      visit root_path
      click_link 'Log out'
      expect(page).to have_content 'Sign in'
      Warden.test_reset! # this will be needed if/when using the warden test helpers in multiple tests
    end

    it "changes a password" do
      visit user_path @user
      click_link 'Change my password'
      new_password = 'new_password'
      fill_in 'Password', with: new_password
      fill_in 'Password confirmation', with: new_password
      fill_in 'Current password', with: @original_password
      click_button 'Change'
      expect(page).to have_content 'You account has been updated successfully'
    end

  end

end