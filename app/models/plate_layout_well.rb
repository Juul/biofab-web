class PlateLayoutWell < ActiveRecord::Base
  belongs_to :eou
  belongs_to :organism
  belongs_to :plate_layout

  def descriptor
    "#{(organism) ? organism.substrain : 'ORGANISM_NA'} | #{(eou) ? eou.descriptor : 'EOU_NA'}"
  end

end
