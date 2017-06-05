class SettingsController < ApplicationController

  # https://github.com/paulca/configurable_engine/blob/master/lib/configurable_engine/configurables_controller.rb
  include ConfigurableEngine::ConfigurablesController

  authorize_resource :class => false

  # overriding inherited method, so can customize the redirect path and flash
  def update
    Configurable.keys.each do |key|
      configurable = Configurable.find_by_name(key) || Configurable.create {|c| c.name = key}
      configurable.update_attribute :value, params[key]
    end
    redirect_to settings_path, :notice => 'Changes successfully updated.'
  end

  def tree_registrant_welcome
    tr = User.tree_registrants
     tr.each do |user|
      puts user.to_yaml
      EventMailer.tree_registrants_welcome(user).deliver    
    end
    flash[:notice] = "Tree registrant emails sent."
    redirect_to settings_path
  end
end