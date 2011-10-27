class Plate < ActiveRecord::Base
  has_many :wells, :class_name => 'PlateWell'
  belongs_to :plate_layout

  def self.analyze(plate_layout, user, dirname)
    begin
      r = RSRuby.instance
      r.source(File.join(Rails.root, 'r_scripts', 'fcs3_analysis.r'))
      # TODO move path to settings.rb
      input_path = File.join(Rails.root, 'public', 'flow_cytometer_input_data')
      r.setwd(input_path)
      
      # The current directory to process
      # This will have one subdir per replicate
      data_path = File.join(input_path, dirname)

      out_path = File.join(Rails.root, 'public', 'flow_cytometer_output', plate_layout.id.to_s)
      if !File.directory?(out_path)
        Dir.mkdir(out_path)
      end
      
#      data = r.analyse(out_path, dirname, :pattern => "pltFAB1_", :layout_path => "plate_layouts")

      data = eval(File.new(File.join(Rails.root, 'r.data')).readlines.join(''))

      plate_names = self.scan_for_plates(data_path)

      puts "======================"
      puts "plate names: " + plate_names.inspect

      plate_names.each do |plate_name|
        plate = Plate.new
        plate.name = plate_name
        plate.plate_layout = plate_layout

        # the raw data for the plate
        plate_data = data[plate_name]

        plate_data['mean.GRN.HLin'].each_index do |i|

          mean = plate_data['mean.GRN.HLin'][i]
          sd = plate_data['sd.GRN.HLin'][i]
          
          well = PlateWell.new
          well.column = ((i % 12) + 1).to_s
          well.row = ((i / 12) + 1).to_s
          well.replicate = Replicate.new

          characterization = Characterization.new
          characterization.value = mean
          characterization.standard_deviation = sd
          well.replicate.characterizations << characterization

          well.save!

          plate.wells << well
        end
        
        plate.save!
      end

#      f = File.new('/tmp/foobar.txt', 'w+')
#      f.puts data.inspect
#      f.close
      
      ProcessMailer.flowcyte_completed(user).deliver
    rescue Exception => e
      ProcessMailer.error(user, e).deliver
    end
  end

  def self.scan_for_plates(path)
    puts path
    plate_names = []
    dir = Dir.new(path)
    dir.each do |entry|
      next if (entry == '.') || (entry == '..')
      plate_path = File.join(path, entry)
      next if !File.directory?(plate_path)
      puts "i have an entry: #{entry}"

      plate_dir = Dir.new(plate_path)
      plate_dir.each do |replicate_entry|
        next if (replicate_entry == '.') || (replicate_entry == '..')        
        replicate_path = File.join(plate_path, replicate_entry)
        next if !File.file?(replicate_path)

        puts "i have a replicate_entry: #{replicate_entry}"

        if replicate_entry.match(/\.fcs3?$/)
          plate_names << entry
          break
        end
        
      end
    end
    plate_names
  end

  # TODO this is hackish
  def well_characterization(row, col)
    well = wells.where(["row = ? AND column = ?", row.to_s, col.to_s]).first
    if !well
      raise "#{row} - #{col}"
    end
    return well.replicate.characterizations.first
  end

end
