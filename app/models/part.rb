class Part < ActiveRecord::Base
  has_many :annotations
  # only if this is a plasmid or chromosomally integrated sequence
  belongs_to :plasmid_info 
  belongs_to :part_type
  belongs_to :project

  before_validation do
    self.sequence = sequence.upcase.gsub(/[^ATGC]+/, '')
    if sequence == ''
      self.sequence = nil
    end
  end

  validates :biofab_id, :presence => true, :uniqueness => true
  validates :sequence, :uniqueness => true

  def to_s
    biofab_id
  end


  

end
