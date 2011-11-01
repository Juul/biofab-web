class PlateWell < ActiveRecord::Base
  belongs_to :plate
  belongs_to :replicate

end
