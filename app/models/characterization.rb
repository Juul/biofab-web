class Characterization < ActiveRecord::Base
  belongs_to :replicate
  belongs_to :characterization_type
  has_and_belongs_to_many :performances
  has_many :measurements

  def self.new_with_type(type_name)
    c = Characterization.new
    c.set_type(type_name)
    return c
  end

  def set_type(type_name)
    self.characterization_type = CharacterizationType.find_by_name(type_name)
  end

end
