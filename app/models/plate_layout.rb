class PlateLayout < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :eou
  belongs_to :organism
  has_many :wells, :class_name => 'PlateLayoutWell'
  has_many :plates

  def well_descriptor_for(part_type_name, row, col)
    well = wells.where(["row = ? AND column = ?", row, col]).includes(:eou).first
    return '' if !well

    # TODO ugly
    if part_type_name == 'organism'
      return '' if !well.organism
      return well.organism.descriptor
    else
      part = well.eou.send(part_type_name)

      return '' if !part
      return part.descriptor
    end

  end

end
