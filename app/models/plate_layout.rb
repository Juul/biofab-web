class PlateLayout < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :eou
  belongs_to :organism
  has_many :wells, :class_name => 'PlateLayoutWell'
  has_many :plates

  def well_at(row, col)
    wells.where(["row = ? AND column = ?", row, col]).includes(:eou).first
  end

  def well_descriptor_at(row, col)
    cur_organism = nil
    cur_eou = nil
    well = wells.where(["row = ? AND column = ?", row, col]).includes(:eou).first
    if !well # not directly specified
      well = wells.where(["row = ? AND column = 0", row]).includes(:eou).first
    end
    if !well # not specified by row
      well = wells.where(["row = 0 AND column = ?", col]).includes(:eou).first
    end
    if !well # not specified by column
      cur_organism = organism
      cur_eou = eou
    else
      cur_organism = well.organism
      cur_eou = well.eou
    end
    "#{(cur_organism) ? cur_organism.substrain : 'ORGANISM_NA'} | #{(cur_eou) ? cur_eou.descriptor : 'EOU_NA'}"
  end

  def well_descriptor_for(part_type_name, row, col)
    return '' if !id
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
