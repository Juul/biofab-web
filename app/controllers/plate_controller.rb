class PlateController < ApplicationController

  def show
    @plate = Plate.includes(:wells => {:replicate => :characterizations}).find(params['id'])

  end

end
