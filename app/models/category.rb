class Category < ActiveRecord::Base
  acts_as_category :order => 'name', :hidden => 'private'
  
  #Validation
  validates_presence_of :name, :group_id, :user_id

  #Relationships
  belongs_to :group
  belongs_to :user
  has_many :documents
  belongs_to :background

  #Indexing
  acts_as_ferret :fields => [ :name, :description ]

  #All the documents in a category, sorted by their last update.
  #This is needed until a bug in activerecord is fixed. (see below)
  #https://rails.lighthouseapp.com/projects/8994/tickets/2346-named_scope-doesnt-override-default_scopes-order-key
  def documents_by_updated
    Document.find(:all, :conditions => {:category_id => self.id}, :order => 'updated_at DESC')
  end

  #Return the reverse of private, for reading purposes
  def not_private
    !self.private
  end

  #Authenticates Access
  #Test if a user can read a category
  #This method bypasses the acts_as_category plugin methods

	has_owner :user
	authenticates_reads :with => :not_private
  authenticates_reads :with => :allow_owner
  authenticates_reads :with_accessor_method => :is_admin
  authenticates_reads :with => :current_user_in_my_group?

  def current_user_in_my_group?
    bypass_auth do
      #bypass authentication allows us to looka at the accessor and group, or something
      if !ActiveRecord::Base.accessor.nil? && ActiveRecord::Base.accessor.in_group?( group )
        true
      else
        false
      end
    end
  end

  def return_my_group
    group
  end

  #Test if a user can write to the category
  authenticates_saves :with => :allow_owner
  authenticates_saves :with => :writable
  authenticates_saves :with_accessor_method => :is_admin
  authenticates_saves :with => :current_user_in_my_group?

  #authenticates_creation :with => IN THE GROUP
 
  autosets_owner_on_create

end
