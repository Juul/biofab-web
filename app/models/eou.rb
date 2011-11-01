class Eou < ActiveRecord::Base
  belongs_to :promoter, :class_name => 'Part'
  belongs_to :five_prime_utr, :class_name => 'Part'
  belongs_to :cds, :class_name => 'Part'
  belongs_to :terminator, :class_name => 'Part'
  has_many :plasmids, :class_name => 'Part'

  def sequence
    promoter.sequence + five_prime_utr.sequence + gene.sequence + terminator
  end

  def descriptor
    descs = []
    descs << promoter.biofab_id_descriptor
    descs << five_prime_utr.biofab_id_descriptor
    descs << cds.biofab_id_descriptor
    descs << terminator.biofab_id_descriptor
    descs.join(' | ')
  end

end
