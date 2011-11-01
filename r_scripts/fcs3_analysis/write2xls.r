
write2xls = function(workbook.path, data, overwrite=TRUE, verbose=FALSE) {
	if (!length(data)) return(-1)
	# First write
	for (i in 1:length(data)) {
		append=TRUE
		if (i == 1 & overwrite==TRUE) append=FALSE
		write.xlsx(data[[i]], workbook.path, sheetName=names(data)[i], append=append) }
	# Then modify formatting
	wb = loadWorkbook(workbook.path)
	#highlight=createCellStyle(wb, fillPattern="LESS_DOTS1")
	ifont=createCellStyle(wb, font=createFont(wb, isItalic=TRUE))
	bfont=createCellStyle(wb, font=createFont(wb, isBold=TRUE))
	for (sheet in getSheets(wb))
		for (row in getRows(sheet)) {
			cells= getCells(list(row), simplify=TRUE)

			if (getCellValue(cells[[length(cells)]])!="OK")
				for (cell in cells)
					setCellStyle(cell, ifont)
			else
				for (cell in cells)
					setCellStyle(cell, bfont)
		}
	saveWorkbook(wb, workbook.path)
	if (verbose) cat("Data saved to :", workbook.path,"\n")
	return(1)
}
