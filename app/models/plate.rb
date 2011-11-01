class Plate < ActiveRecord::Base
  has_many :wells, :class_name => 'PlateWell'
  belongs_to :plate_layout

  def self.analyze(plate_layout, fluo_channel, user, dirname)
    begin

      # TODO move path to settings.rb
      input_path = File.join(Rails.root, 'public', 'flow_cytometer_input_data')
      script_dir = File.join(Rails.root, 'r_scripts', 'fcs3_analysis')

      # Initialize R and load the r source file
      r = RSRuby.instance
      r.setwd(script_dir)
      r.source(File.join(script_dir, 'fcs3_analysis.r'))

      # The current directory to process
      # This will have one subdir per replicate
      data_path = File.join(input_path, dirname)

      out_path = File.join(Rails.root, 'public', 'flow_cytometer_output', plate_layout.id.to_s)
      if !File.directory?(out_path)
        Dir.mkdir(out_path)
      end

      f = File.new(File.join(Rails.root, 'foobar.out'))
      data = eval(f.readlines.join(''))
      f.close

#      data = r.run(out_path, data_path, :fluo => fluo_channel)

      # TODO remove this debug code
      f = File.new(File.join(Rails.root, 'foobar.out'), 'w+')
      f.puts(data.inspect)
      f.close

      plate_names = self.scan_for_plates(data_path)

      # characterizations
      chars = []
      8.times do |row|
        chars[row] = []
        12.times do |col|
          chars[row][col] = []
        end
      end

      plate_names.each do |plate_name|
        plate = Plate.new
        plate.name = plate_name
        plate.plate_layout = plate_layout

        # the raw data for the plate
        plate_data = data[plate_name]

        plate_data['mean.GRN.HLin'].each_index do |i|
          break if i > 95 # don't accept more than 96 wells

          mean = plate_data['mean.GRN.HLin'][i]
          sd = plate_data['sd.GRN.HLin'][i]

          col = (i % 12)
          row = (i / 12)

          well = PlateWell.new
          well.column = (col+1).to_s
          well.row = (row+1).to_s
          well.replicate = Replicate.new

          characterization = Characterization.new
          characterization.value = mean
          characterization.standard_deviation = sd

          chars[row][col] << characterization

          well.replicate.characterizations << characterization

          well.save!

          plate.wells << well
        end
        
        plate.save!
      end

      summary_data = data['Summary']

      # Performances

      
      chars.each_index do |row|
        row_a = chars[row]
        row_a.each_index do |col|
          col_chars = row_a[col]
          perf = Performance.new
          col_chars.each do |char| # loop through the characterizations for the different replicates
            perf.characterizations << char
          end
          i = row * 12 + col
          perf.value = summary_data['mean.mean.GRN.HLin'][i]
          perf.standard_deviation = summary_data['sd.mean.GRN.HLin'][i]
          perf.save!
        end
      end
     
      
      ProcessMailer.flowcyte_completed(user, plate_layout.id).deliver
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

  def well_at(row, col)
    wells.where(["row = ? AND column = ?", row.to_s, col.to_s]).first
  end

  # TODO this is hackish
  def well_characterization(row, col)
    well = wells.where(["row = ? AND column = ?", row.to_s, col.to_s]).first
    if !well
      raise "#{row} - #{col}"
    end
    return well.replicate.characterizations.first
  end

  def xls_add_plate_sheet(workbook, sheet_name)
    sheet = workbook.create_worksheet
    sheet.name = sheet_name

    row_name_format = Spreadsheet::Format.new(:weight => :bold)
    col_name_format = Spreadsheet::Format.new(:weight => :bold)

    # write row names
    8.times do |row|
      row_name = ((?A)+row).chr
      sheet[row+1, 0] = row_name
      sheet.row(row+1).set_format(0, row_name_format)
    end

    # write column names
    12.times do |col|
      col_name = (col+1).to_s
      sheet[0, col+1] = col_name
      sheet.row(0).set_format(col+1, col_name_format)
    end
    sheet
  end

  def xls_add_plate_layout_sheet(workbook)
    sheet = xls_add_plate_sheet(workbook, 'Plate layout')
    1.upto(8) do |row|
      1.upto(12) do |col|
        sheet[row, col] = plate_layout.well_descriptor_at(row, col)
      end
    end
    sheet
  end

  def get_characterization_xls
    workbook = Spreadsheet::Workbook.new

    layout_sheet = xls_add_plate_layout_sheet(workbook)
    value_sheet = xls_add_plate_sheet(workbook, 'Characterization')
    sd_sheet = xls_add_plate_sheet(workbook, 'Standard deviation')

    wells.each do |well|
      characterization = well.replicate.characterizations.first
      value_sheet[well.row.to_i, well.column.to_i] = characterization.value
      sd_sheet[well.row.to_i, well.column.to_i] = characterization.standard_deviatio
    end

    out_path = File.join(Rails.root, 'public', "plate_#{id}_characterization.xls")
    workbook.write(out_path)
    out_path
  end

  def get_performance_xls
    workbook = Spreadsheet::Workbook.new

    layout_sheet = xls_add_plate_layout_sheet(workbook)
    value_sheet = xls_add_plate_sheet(workbook, 'Performance')
    sd_sheet = xls_add_plate_sheet(workbook, 'Standard deviation')

    wells.each do |well|
      performance = well.replicate.characterizations.first.performances.first
      value_sheet[well.row.to_i, well.column.to_i] = performance.value
      sd_sheet[well.row.to_i, well.column.to_i] = performance.standard_deviation
    end

    out_path = File.join(Rails.root, 'public', "plate_#{id}_performance.xls")
    workbook.write(out_path)
    out_path
  end


end
