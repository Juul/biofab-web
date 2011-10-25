class Characterization < ActiveRecord::Base
  belongs_to :replicate
  belongs_to :characterization_type
  has_and_belongs_to_many :performances
  has_many :measurements
end
