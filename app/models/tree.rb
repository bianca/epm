class Tree < ActiveRecord::Base


  before_validation :check_species

  strip_attributes

  belongs_to :owner, class_name: "User"
  belongs_to :submitter, class_name: "User"
  has_many :event_trees
  has_many :events, :through => :event_trees

  accepts_nested_attributes_for :owner, :reject_if => :legit_owner
  accepts_nested_attributes_for :submitter, :reject_if => :legit_owner
  #attr_accessible :lname, :owner_attributes
  #validates :lname, presence: true

  def self.quality_labels 
  {
    "1 - Not Edible" => 1,
    "2 - Some Edible" => 2,
    "3 - Edible" => 3,
    "4 - Good" => 4,
    "5 - Great" => 5
  }
  end

  def legit_owner(attributes)
    attributes[:fname].blank?
    attributes[:lname].blank?
    attributes[:phone].blank?
    attributes[:email].blank?
    attributes[:address].blank?
  end

  acts_as_mappable through: :owner

  attr_accessor :species_other

  enum keep: {
    :yes => 0,
    :abit => 1,
    :no => 2
  }


  enum relationship: {
    :propertyowner => "propertyowner",
    :friend => "friend",
    :tenant => "tenant"
  }

  def self.csv(trees)
    CSV.generate force_quotes: true do |csv|
      csv << ['id', 'species', 'sub-species','home ward', 'address', 'first name', 'last name', 'email', 'phone number', 'First Registered', "Submitter Name", "Submitter Email", "Submitter Phone"]
      trees.each do |tree|
        if tree.submitter.present?
          csv << [tree.id, tree.species, tree.subspecies, tree.owner.home_ward, tree.owner.address, tree.owner.fname, tree.owner.lname, tree.owner.email, tree.owner.phone, tree.owner.created_at.to_date.to_s, tree.owner.fname+" "+tree.owner.lname, tree.owner.email, tree.owner.phone,]
        else
          csv << [tree.id, tree.species, tree.subspecies, tree.owner.home_ward, tree.owner.address, tree.owner.fname, tree.owner.lname, tree.owner.email, tree.owner.phone, tree.owner.created_at.to_date.to_s]
        end
      end
    end
  end



  def self.relationship_labels 
  {
    :propertyowner => "property owner",
    :friend => "friend",
    :tenant => "tenant"
  }
  end

  def self.keep_labels 
  {
    "Yes" => :yes,
    "Yes, but less than 1/3" => :abit,
    "No" => :no
  }
  end

  def self.keep_result_labels 
  {
    "1/3" => :yes,
    "less than 1/3" => :abit,
    "none" => :no
  }
  end

  enum height: {
    :lt1 => 1,
    :bt1n2 => 2,
    :bt2n3 => 3,
    :gt3 => 4
  }

  def self.height_labels
  {
    "> 3 storeys (> 9 metres, 30 feet)" => :gt3,
    "2-3 storeys (20-30 feet, 6-9 metres)" => :bt2n3,
    "1 - 2 storeys (10-20 feet, 3-6 metres)" => :bt1n2,
    "< 1 storey (< 10 feet, 3 metres)" => :lt1
  }
  end

  def self.types
    ["Apple","Apricot","Cherry","Crabapple","Elderberry","Ginkgo","Grape","Mulberry","Pawpaw","Peach","Pear","Persimmon","Plum","Quince","Serviceberry"]
  end

  def check_species
    if self.species.blank? && self.species_other.present?
      self.species = self.species_other
    end
  end 

  def self.closest(origin, ids, page)
    @page = 1
    if page.present? && page.to_i > 1
      @page = page.to_i
    end
    @trees = Tree.joins(:owner).by_distance(:origin => origin).where.not({'trees.id' => ids}).page(@page).per(10)
  end

  scope :search, ->(q) {
    db = Rails.configuration.database_configuration[Rails.env]["adapter"]
    like = db == 'postgresql' ? 'ILIKE' : 'LIKE'
    joins(:owner).where("trees.subspecies #{like} ? OR trees.species #{like} ? OR users.address #{like} ?", "%#{q}%", "%#{q}%", "%#{q}%")
  }
  
end
