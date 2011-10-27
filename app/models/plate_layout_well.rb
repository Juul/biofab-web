class PlateLayoutWell < ActiveRecord::Base
  belongs_to :eou
  belongs_to :organism
  belongs_to :plate_layout
end
