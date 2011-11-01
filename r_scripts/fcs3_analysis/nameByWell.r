
nameByWell = function(flowset)
{
	id =c()
	for (i in 1:length(flowset))
	{
		
		id = append(id, flowset[[i]]@description$`$WELLID`)
	}
	sampleNames(flowset) = id
	flowset =flowset[order(sampleNames(flowset)),]
	return(flowset)
}
