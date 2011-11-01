

run = function(out_path, 
               path, 
               pattern="", 
               layout.path="", 
               layout.pattern=pattern, 
               fluo="", 
               clean=TRUE, 
               cluster=TRUE, 
               init.gate="ellipse", 
               mode="auto", 
               clust_levels=c(0.95,0.95), 
               verbose=TRUE) {

	# Guess whether to go in duplicate (if folder with correct pattern detected) or single mode (otherwise)
	folders = dir(path=path, recursive=FALSE, full.names=TRUE, pattern=pattern)

	for(ignored.folders in c("plot","cleaned_data","bad")) {
		folders = folders[grep(ignored.folders, basename(folders), ignore.case=TRUE, value=FALSE, invert=TRUE)]
  }

	folders = folders[file.info(folders)$isdir==TRUE]

	if (mode == "auto") {
		if(length(folders) == 0) {
      mode = "single"	
    } else {
      mode = "replicate"
    }
  }

	if (mode == "single") {
		if (verbose) cat("Run initiated in single mode\n")
		folders   = path
		splitpath = unlist(strsplit(path,"/"))
		path      = do.call(file.path, as.list(splitpath[1:(length(splitpath)-1)]))
  } else if (verbose) {
		cat("Run initiated in replicate mode\nFound the following folders:\n")
		cat(folders,sep="\n")
  }

	# Get layout file
	ismapped = FALSE
	mapping  = FALSE
	if((layout.path != "") && (!file.info(layout.path)$isdir))
	{
		if (verbose) cat("Specified layout: ", layout.path,"\n")
		mapping = getMapping(layout.path)
		ismapped=TRUE
	}
	else if (layout.pattern != "")
	{
		layout.files = list.files(path=layout.path, pattern=layout.pattern, full.names=TRUE)

		if (length(layout.files) == 1) {
			if (verbose) cat("Found the following layout: ", layout.files,"\n")
			mapping = getMapping(layout.files)
			ismapped=TRUE }
		else if (length(layout.files) > 1) {
			if (verbose) cat("Found several layouts, please refine matching pattern:\n")
			return(print(layout.files)) }
		else if (verbose)  {
      cat("No layout found...\n")
      return
    }
	}
	if (ismapped == FALSE) # try to search locally for files containing layout and same name as input
	{
		layout.files = list.files(path=path, pattern="layout", recursive=TRUE, full.names=TRUE)
		layout.files = layout.files[grep(basename(path), layout.files)]
		if (length(layout.files) == 1) {
			if (verbose) cat("Found the following layout: ", layout.files,"\n")
			mapping = getMapping(layout.files)
			ismapped=TRUE }
		else if (length(layout.files) > 1) {
			if (verbose) {
				cat("Found several possible layouts, in specified path", layout.files,sep="\n")
				cat("Selected: ", min(layout.files), "\n")
      }
			mapping = getMapping(min(layout.files))
			ismapped=TRUE }
	}

	if (ismapped == FALSE) {
		if(verbose) {
      cat("No layout specified...\n")
    }
  }

  # == Mapping read (or no mapping) ==

	# Process fluo
	# Processed in sub-functions

	if(fluo == "" & !ismapped & verbose) {
    cat("No fluorescence channel selected...\n")
    return(FALSE)
  }

	# Cluster and restrictions
	if(is.logical(cluster)) {
		if(cluster == TRUE) {
      clusterize = TRUE
    }
  }	else if(is.list(cluster)) {
		clusterize=TRUE
	} else {
		clusterize=FALSE
  }


	# == Analyze the data ==

	data = vector("list")
	mixed = vector("list")

	for(i in 1:length(folders)) {

		if(verbose) {
      cat("Reading folder ",folders[i],"...\n",sep="")
    }

		pheno=FALSE
		if(length(list.files(path=folders[i], pattern="annotation.txt", full.names=FALSE))==1) {
			pheno="annotation.txt"
    }

		flowset=read.flowSet(path=folders[i], pattern=".fcs", phenodata=pheno)

		if(clean==TRUE) {

			if(verbose) {
        cat("Cleaning... ")
      }

			flowset = clean.flowSet(flowset, mapping, fluo, scale="Log")

      # === Select filter ===

			filter = NULL
			if(init.gate == "ellipse") {
				if(verbose) {
          cat("Recapitulate ellipsoidal gating... \n")
        }
				filter = ellipseGateFilter(flowset)

			} else if(init.gate == "rectangle") {
				if(verbose) {
          cat("Recapitulate rectangular gating... \n")
        }
				filter = rectangularGateFilter(flowset)
			}

      # === Filter the data ===

			flowset = Subset(flowset, filter)

      # === Clustering ===

			second.peak=NULL
			if(clusterize) {
				if(ismapped!=FALSE | fluo!="") {

					if(verbose) {
            cat("Clustered Gating...")
          }

					if(pattern!="") {
            plotout = file.path(path,paste("Plots",pattern,sep="_"))
          } else {
            plotout = file.path(path,"Plots")
          }

					restrict = FALSE

					if(is.list(cluster)) {
            restrict=cluster[[i]]
          }

					clusters = clustGating(flowset, mapping=mapping, fluo=fluo, scale="Log", cluster_rule=restrict, output=c(out_path, basename(folders[i])), levels=clust_levels)

					flowset = clusters[[1]]
					second.peak = clusters[[2]]
				}
      }

      # === Save FCS files ===



			write.flowSet(flowset, file.path(out_path,paste("Cleaned_data",pattern,sep="_"),"Cluster1",basename(folders[i])),filename=sampleNames(flowset))

			if(class(second.peak) == "flowSet") {
        write.flowSet(second.peak, file.path(out_path, paste("Cleaned_data",pattern,sep="_"),"Cluster2",basename(folders[i])),filename=sampleNames(second.peak))
      }

		} else { # no cleaning

			cat("NB: Data processed as is... \n")
			flowset = nameByWell(flowset)
			second.peak = NULL
		}

		if(verbose) {
      cat("Processing data... \n")
    }

		processed.data = extractData(flowset, mapping, fluo)
		data[[basename(folders)[i]]] = processed.data[[1]]

		if(verbose) {
      cat("Writing xlsx... \n")
    }

		overwrite=FALSE
		if(i==1) {
      overwrite=TRUE
    }

		print(data[basename(folders)[i]])

#		write2xls(file.path(path,paste("Summary_",pattern,".xlsx",sep="")),data[basename(folders)[i]], overwrite=overwrite, verbose=verbose)

		if(!is.null(processed.data[[2]])) {
			multi.ecdf(processed.data[[2]])
    }

		if (class(second.peak) == "flowSet") {
			processed.data = extractData(second.peak, mapping, fluo)
			mixed[[basename(folders)[i]]] = processed.data[[1]]
		}

		if(verbose) {
      cat("Done.\n")
    }
	} 

	# == Create summary ==

	if(mode=="replicate") {
		combined = combine.replicates(data)
		data = append(data, data.frame(Summary=0), 0)
		data$Summary = combined
  }

	if(!length(mixed)) {
		mixed=NULL
  }

	## export to xlsx
# write2xls(file.path(out_path,paste("Summary_",pattern,".xlsx",sep="")),data,verbose=verbose)
# write2xls(file.path(out_path,paste("Cluster2_",pattern,".xlsx",sep="")),mixed,verbose=verbose)

	if(verbose) {
    cat("All done!\n")
  }

	return(data)
}
