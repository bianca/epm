class MakeAdminNotesText < ActiveRecord::Migration
  def change
   	remove_column :users, :admin_notes
    add_column :users, :admin_notes, :text 	
  end
end
