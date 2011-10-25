class Replicate < ActiveRecord::Base
  belongs_to :strain
  has_many :characterizations
end
