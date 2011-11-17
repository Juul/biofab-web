class PlateLayout < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :eou
  belongs_to :organism
  has_many :wells, :class_name => 'PlateLayoutWell'
  has_many :plates

  def analyze_replicate_dirs(replicate_dirs, user)
    begin
      cur_rep_dir = ''
      replicate_dirs.each do |rep_dir|
        cur_rep_dir = rep_dir
        self.analyze_replicate_dir(rep_dir, user)
      end
      ProcessMailer.flowcyte_completed(user, self.id).deliver
      
    rescue Exception => e
      
      ProcessMailer.error(user, e, cur_rep_dir).deliver

    end
  end


  def get_well_channels
    well_channels = {}
    wells.each do |well|
      if well.channel.blank?
        raise "plate layout well '#{well.name}' in plate layout '#{name}' has no fluorescence channel"
      end
      well_channels[well.name] = well.channel
    end
    well_channels
  end

  def analyze_replicate_dir(replicate_dir, user)

    require 'tmpdir'
    
    r = RSRuby.instance
    
    script_path = File.join(Rails.root, 'r_scripts', 'fcs-analysis', 'r_scripts')
    main_script = File.join(script_path, 'fcs3_analysis.r')
    
    out_dir = Dir.mktmpdir('biofab_fcs')
    
    dump_file = File.join(Rails.root, 'out.dump')
    
    # fluo = 'RED'
    fluo = 'GRN' # fallback fluo if not defined for channel

    #init_gate = 'ellipse'
    init_gate = 'rectangle'
    
    fcs_file_paths = []
    
    dir = Dir.new(replicate_dir)
    dir.each do |fcs_file|
      next if (fcs_file == '.') || (fcs_file == '..')
      fcs_file_path = File.join(replicate_dir, fcs_file)
      next if File.directory?(fcs_file_path)
      fcs_file_paths << fcs_file_path
    end
    
    r.setwd(script_path)
    r.source(main_script)

    data_set = Exceptor.call_r_func(r, r.batch, out_dir, fcs_file_paths, :fluo_channel => fluo, :well_channels => get_well_channels, :init_gate => init_gate, :verbose => true)
    
    # TODO remove this debug code
    f = File.new(dump_file, 'w+')
    f.puts(data_set.inspect)
    f.close
    
    plate = Plate.new
    plate.plate_layout = self
    plate.name = self.name # TODO what would be a good name?

    data_set.each_pair do |input_file_path, data|

      if !data || !data['error'].blank?
        next
      end
      
      well = PlateWell.new
      plate.wells << well

      original_fcs_file = DataFile.from_local_file(input_file_path, 'original_fcs_file')
      well.files << original_fcs_file

      plot_file = DataFile.from_local_file(data['outfile_plot'], 'plot')
      well.files << plot_file

      well.row, well.column = PlateWell.well_name_to_row_col(data['well_name'])
      well.replicate = Replicate.new
      
      c = Characterization.new_with_type('mean')
      c.value = data['mean']
      well.replicate.characterizations << c

      c = Characterization.new_with_type('standard_deviation')
      c.value = data['standard_deviation']
      well.replicate.characterizations << c

      c = Characterization.new_with_type('variance')
      c.value = data['variance']
      well.replicate.characterizations << c

      c = Characterization.new_with_type('event_count')
      c.value = data['event_count']
      well.replicate.characterizations << c

      c = Characterization.new_with_type('cluster_count')
      c.value = data['cluster_count']
      well.replicate.characterizations << c

      # TODO unpretty
      c = Characterization.new_with_type('events')
      c.value = 0.0
      c.description = data['events']
      well.replicate.characterizations << c
      
      well.save!
    end

    plate.save!

  end


  # find dirs containing a dir for each replicate, each containing at least 96 fcs files
  def self.list_valid_fcs_dirs
    dirs = []
    if Settings['fcs_input_path_is_relative']
      outer_path = File.join(Rails.root, Settings['fcs_input_path'])
    else
      outer_path = Settings['fcs_input_path']
    end

    dir = Dir.new(outer_path)
    dir.each do |entry|
      next if (entry == '.') || (entry == '..')
      entry_path = File.join(outer_path, entry)
      next if !File.directory?(entry_path)

      subdir = Dir.new(entry_path)
      subdir_count = 0
      subdir.each do |subentry|
        next if (subentry == '.') || (subentry == '..')
        subentry_path = File.join(entry_path, subentry)
        next if !File.directory?(subentry_path)
        subsubdir = Dir.new(subentry_path)
        fcs_count = 0
        subsubdir.each do |subsubentry|
          next if (subsubentry == '.') || (subsubentry == '..')
          if subsubentry.match(/.*\.fcs$/)
            fcs_count += 1
          end
        end
        if (fcs_count >= 96) 
          subdir_count += 1
        end
      end
      if subdir_count > 0
        dirs << {
          :name => entry,
          :path => entry_path,
          :num_files => subdir_count,
          :created_at => File.ctime(subdir.path)
        }      
      end
    end
    dirs
  end

  def well_at(row, col)
    wells.where(["row = ? AND column = ?", row, col]).includes(:eou).first
  end

  def brief_well_descriptor_at(row, col, opts={})
    well = wells.where(["row = ? AND column = ?", row, col]).includes(:eou).first
    return 'NA' if !well
    desc = ''
    desc += "#{well.organism.brief_descriptor} | " if well.organism
    desc += well.eou.descriptor(opts) if well.eou
  end

  def well_descriptor_at(row, col, opts={})
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
    "#{(cur_organism) ? cur_organism.brief_descriptor : 'ORGANISM_NA'} | #{(cur_eou) ? cur_eou.descriptor(opts) : 'EOU_NA'}"
  end

  def well_descriptor_for(part_type_name, row, col)
    return '' if !id
    well = wells.where(["row = ? AND column = ?", row, col]).includes(:eou).first
    return '' if !well

    # TODO ugly
    if part_type_name == 'organism' 
      part = well.organism
      return '' if !part
      part.descriptor
    elsif part_type_name == 'channel'
      return '' if well.channel.blank?
      well.channel
    else
      part = well.eou.send(part_type_name)
      return '' if !part
      part.descriptor
    end

  end

end
