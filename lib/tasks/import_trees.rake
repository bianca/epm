task :importTrees => :environment do

	tree_errors = []
	user_errors = []
	rows = CSV.read(Rails.root + "app/assets/data/formdata_update.csv")
	#header = rows.first.map{|c| c.downcase }
    rows = rows[1..-1]
    rows.each do |row|
    	user_id1 = nil 
    	user_id2 = nil
    	if row[21].to_s.strip != ""

		    address = row[21].to_s.strip + ", "
		    if row[22].present?
		     address = address + row[22].to_s.strip + ", "
		    end
		    address = address + row[23].to_s.strip + ", " + row[24].to_s.strip + ", " + row[25].to_s.strip + ", " + row[26].to_s.strip
		    existing_user = User.where(address: address).first

		    # then we have owner information and id

		    if existing_user.present?
		    # get that user_id, store it for now
		    	user_id1 = existing_user.id
		    end

		    ladder = "yes" if row[29].to_s.strip == "Yes, I have a ladder."
		    ladder = "no" if row[29].to_s.strip == "I won't be able to get a ladder."
		    ladder = "borrow" if row[29].to_s.strip == "I can borrow a ladder from a friend or neighbour."
		    keep = "yes" if row[74].to_s.strip == "Yes, please!"
		    keep = "no" if row[74].to_s.strip == "No, thanks."
		    keep = "abit" if row[74].to_s.strip == "Yes, but less than 1/3 is more than enough."
		    u = User.new
		    u.fname = row[7]
		    u.lname = row[8]
		    if u.lname.blank?
		    	u.lname = "Unknown"
		    end
		    u.email = row[9]
		    if u.email.blank?
		    	u.email = (User.last.id + 1).to_s + "@example.com" if u.email.blank?	    	
		    	#u.email = "placeholder_" + Time.now.strftime("%Y%m%d%H%M%S").to_s + "@example.com"
		    end
		    u.created_at = Time.zone.now
		    u.updated_at = Time.zone.now
		    u.snail_mail = row[5].to_s.strip != "Do not mail"
		    u.admin_notes = row[2].to_s.strip	if row[2].present?
		    u.password = Devise.friendly_token.first(8)
		    u.phone = row[10].to_s 
			u.can_email = true
		    u.can_email = false if row[3].present?
		    u.can_mail = true
		    u.can_mail = false if row[5].present?
		    u.can_phone = true
		    u.can_phone = false if row[4].present?   
		    if row[11].present? && row[11].to_i != 0
		    	u.phone = "Day: " + u.phone + " - Evening: " + row[11].to_s
		    end
		    if u.phone.blank?
		    	u.phone = "0000000000"
		    end	
		    	   
		    # the last user was a submitter, must create owner, add address to this
		    if row[15].present? && existing_user.blank?
		    	u.skip_confirmation!
		    	puts u.to_yaml	
		    	u.add_trees = "1"
		    	u.save
		    	 puts "submitter"
		    	 puts u.errors.full_messages
		    		if u.errors.present?
		    			user_errors.push(u)
		    		end
			    u2 = User.new
			    puts row.length
			    puts row[84]
			    u2.created_at = Time.zone.now
			    u2.updated_at = Time.zone.now
			    u2.fname = row[15]
			    u2.lname = row[16]
			    if u2.lname.blank?
		    		u2.lname = "Unknown"
		    	end
			    u2.email = row[19]
			    u2.can_email = true
			    u2.can_email = false if row[3].present?
			    u2.can_mail = true
			    u2.can_mail = false if row[5].present?
			    u2.can_phone = true
			    u2.can_phone = false if row[4].present?
			   	if u2.email.blank?
			    	u2.email = (User.last.id + 1).to_s + "@example.com" if u2.email.blank?		   		
		    		#u2.email = "placeholder_" + Time.now.strftime("%Y%m%d%H%M%S").to_s + "@example.com"
		    	end
			    u2.phone = row[17].to_s
			    u2.snail_mail = row[5].to_s.strip != "Do not mail"
			    u2.contactnotes = row[20].to_s.strip if row[20].present?
			    u2.password = Devise.friendly_token.first(8)
			    if row[18].present? && row[18].to_i != 0
			    	u2.phone += " - " + row[18].to_s
			    end
			    if u2.phone.blank?
		    		u2.phone = "0000000000"
		    	end	
			    u2.address = address
			    u2.ladder = ladder
			    u2.propertynotes = ""
			    u2.propertynotes = row[75] if row[75].present?
			    u2.propertynotes += "\n" + row[76] if row[76].present?
			    u2.home_ward = row[27]
			    u2.skip_confirmation!
			    puts "owner before saving"
			    puts u2.to_yaml	
			    u2.add_trees = "1"
			    u2.save
			    if u2.errors.present?
		    		user_errors.push(u2)
		    	end
			    puts u2.errors.full_messages
			    if u2.errors.blank?
			    	u2.roles.create name: :tree_owner			    
			   		user_id2 = u2.id
			   	end
			elsif row[15].present? && existing_user.present?
			# the last user was a submitter, must use queried user as owner_id
				user_id2 = existing_user.id
				 puts "exists"
				 puts u.errors.full_messages
				 puts existing_user.to_yaml
		    elsif row[15].blank? && existing_user.blank?
		    # the last user was an owner, add address, that's it
			    u.address = address
			    u.propertynotes = ""
			    u.propertynotes = row[75] if row[75].present?
			    u.propertynotes += "\n" + row[76] if row[76].present?
			    u.ladder = ladder
			    u.home_ward = row[27]
			    u.skip_confirmation!
			    puts "just new owner before save"
			    puts u.to_yaml
			    u.add_trees = "1"	
				u.save
	    		if u.errors.present?
	    			user_errors.push(u)
	    		end
				user_id1 = u.id    
		    end
		    extranotes = ""
		    #extranotes += row[1].to_s.strip if row[1].present?
		    
		    # Trees
		    g = 7
		    for i in 0..5
		    	gap = g*i
		    	if row[31+gap].present? || row[32+gap].present? 
		    		notes = ""
		    		t = Tree.new
	    			if row[14] == "I am the tenant -  with property owner's permission"	
	    				t.relationship = :tenant	    			    			
	    			elsif row[14] == "I am the property owner"
	    				t.relationship = :propertyowner	    				
	    			elsif row[14] == "I am a friend or neighbour - with property owner's permission" 		
	    				t.relationship = :friend
	    			end
		    		t.treatment = row[73].to_s if row[73].present?
		    		puts "user_id2"
		    		puts user_id2.present?.to_yaml
		    		puts user_id2.to_yaml
		    		if user_id2.present?
		    			t.owner_id = user_id2
		    			t.submitter_id = user_id1
		  			else
		  				t.owner_id = user_id1
		    		end
		    		t.species = "Unknown"
		    		if row[31+gap].present? && row[31+gap].to_s != "Other (specify below)"
		    			t.species = row[31+gap].to_s.strip
		    		elsif row[32+gap].present? 
						t.species = row[32+gap].to_s.strip
		    		end
		    		t.keep = keep
		    		t.subspecies = row[33+gap].to_s if row[33+gap].present?
		    		t.ripen = row[34+gap].to_s.strip if row[34+gap].present?
		    		if row[35+gap].present?	   
		    			if row[35+gap] == "> 3 storeys (> 9 metres, 30 feet)"	
		    				t.height = 4 	    			    			
		    			elsif row[35+gap] == "2-3 storeys (20-30 feet, 6-9 metres)"
		    				t.height = 3 	    				
		    			elsif row[35+gap] == "1 - 2 storeys (10-20 feet, 3-6 metres)" 		
		    				t.height = 2 
		    			elsif row[35+gap] == "< 1 storey (< 10 feet, 3 metres)" 		
		    				t.height = 1 
		    			end
		    		end	
		    		t.created_at = Time.zone.now
		  			t.pickable = true
		     		t.pickable = false if row[36+gap].present? || row[1].present?
		     		t.not_pickable_reason = row[36+gap].to_s if row[36+gap].present?	
		     		t.not_pickable_reason += row[1].to_s if row[1].present? && t.not_pickable_reason.present?
		     		t.not_pickable_reason = row[1].to_s if row[1].blank? && t.not_pickable_reason.present?   		
		     		#notes += "\nNot Pickable because:" +  row[36+gap].to_s if row[36+gap].present?	    			
		    		notes += "\n" + row[37+gap].to_s.strip if row[37+gap].present?

		    		if notes.present? || extranotes.present?
		    			t.additional = ""
		    			t.additional += notes if notes.present?
		    			t.additional += extranotes if extranotes.present?
		    		end
		    		t.save
		    		if t.errors.present?
		    			tree_errors.push(t)
		    		end
		    	end

		    end

		end

    end
	CSV.open(Rails.root + "app/assets/data/error_users.csv","ab") do |csv|
     user_errors.each do |user|
          csv << [user.errors.full_messages.to_yaml, user.home_ward, user.address, user.fname, user.lname, user.email, user.phone]

      end
    end
	CSV.open(Rails.root + "app/assets/data/error.csv","ab") do |csv|
      csv << ['id', 'species', 'sub-species','home ward', 'address', 'first name', 'last name', 'email', 'phone number', 'First Registered', "Submitter Name", "Submitter Email", "Submitter Phone"]
      tree_errors.each do |tree|
          csv << [tree.errors.full_messages.to_yaml, tree.species, tree.subspecies, tree.owner.home_ward, tree.owner.address, tree.owner.fname, tree.owner.lname, tree.owner.email, tree.owner.phone, tree.owner.created_at.to_date.to_s, tree.submitter.fname+" "+tree.submitter.lname, tree.submitter.email, tree.submitter.phone]

      end
    end

end
