class PlateWell < ActiveRecord::Base
  belongs_to :plate
  belongs_to :replicate
  has_many :files, :class_name => 'PlateWellDataFile'
end
