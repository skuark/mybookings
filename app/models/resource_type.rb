class ResourceType < ActiveRecord::Base

  has_many :resources
  has_and_belongs_to_many :users, join_table: 'user_managed_resource_types'

  validates :name, presence: true

  def self.by_name
    order(name: :asc)
  end
  
  def resources_number
    self.resources.count
  end

  # TODO: Move to policy (resource_policy)
  def managed_by? user
    self.users.exists? user
  end

end