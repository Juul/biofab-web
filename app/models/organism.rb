class Organism < ActiveRecord::Base
  has_many :strains

  validates_presence_of :species
  validates_format_of :url, :with => URI::regexp(%w(http https)), :allow_nil => true, :allow_blank => true

  def to_s
    "#{substrain}"
  end

end
