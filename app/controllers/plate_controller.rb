class PlateController < ApplicationController

  def show
    @plate = Plate.includes(:wells => {:replicate => :characterizations}).find(params['id'])
  end

  def characterization_xlsx
    plate = Plate.find(params['id'])
    path = plate.get_xlsx_characterization
    send_file(path, :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def characterization_sd_xlsx
    plate = Plate.find(params['id'])
    path = plate.get_xlsx_characterization_sd
    send_file(path, :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def performance_xlsx
    plate = Plate.find(params['id'])
    path = plate.get_xlsx_performance
    send_file(path, :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def performance_sd_xlsx
    plate = Plate.find(params['id'])
    path = plate.get_xlsx_performance_sd
    send_file(path, :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end


end
