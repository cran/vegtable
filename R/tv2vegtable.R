# TODO:   Import vegetation dataset into a "VegTable" object
# 
# Author: Miguel Alvarez
################################################################################

tv2vegtable <- function(db, tv_home=tv.home(), skip_empty_relations=TRUE,
		skip_scale, clean=TRUE) {
    # Import meta data ---------------------------------------------------------
    description <- unlist(c(db, read.dbf(file.path(tv_home, "Data", db,
                                    "tvwin.dbf"), as.is=TRUE)[,c("FLORA",
                                    "DICTIONARY"), drop=FALSE]))
    names(description) <- c("db_name","sp_list","dictionary")
    # Importing samples --------------------------------------------------------
    samples <- read.dbf(file.path(tv_home, "Data", db, "tvabund.dbf"),
            as.is=TRUE)
    colnames(samples)[colnames(samples) == "RELEVE_NR"] <- "ReleveID"
    colnames(samples)[colnames(samples) == "SPECIES_NR"] <- "TaxonUsageID"
    colnames(samples)[grepl("ORIG_NAME", colnames(samples))] <- "ORIG_NAME"
    samples$COVER_CODE[samples$COVER_CODE == "9X"] <- "100"
    samples$COVER_CODE[samples$COVER_CODE == "99"] <- "100"
    # Importing header data ----------------------------------------------------
    header <- read.dbf(file.path(tv_home, "Data", db, "tvhabita.dbf"),
            as.is=TRUE)
    colnames(header)[colnames(header) == "RELEVE_NR"] <- "ReleveID"
    # Formating dates and some numeric variables
    header$DATE <- as.Date(header$DATE, format="%Y%m%d")
    header$ALTITUDE <- as.numeric(header$ALTITUDE)
    header$INCLINATIO <- as.numeric(header$INCLINATIO)
    # replacing zero values with NAs
    cat("zero values will be replaced by NAs", "\n")
    for(i in colnames(header)) {
        if(is.numeric(header[,i])) header[,i][header[,i] == 0] <- NA
    }
    remarks <- read.dbf(file.path(tv_home, "Data", db, "remarks.dbf"),
            as.is=TRUE)
    remarks <- split(remarks$REMARKS, remarks$RELEVE_NR)
    for(i in as.integer(names(remarks))) {
        header[header$ReleveID == i, "REMARKS"] <- paste(header[
                        header$ReleveID == i, "REMARKS"],
                paste(remarks[[paste(i)]], collapse=" "), collapse=" ")
    }
    # Importing coverconvert ---------------------------------------------------
    if(!is.na(description["dictionary"])) {
        cover_home <- file.path(tv_home, "popup", description["dictionary"],
                "tvscale.dbf")
    } else cover_home <- file.path(tv_home, "popup", "tvscale.dbf")
    coverconvert <- tv2coverconvert(cover_home)
	if(!missing(skip_scale)) {
		coverconvert@value <- coverconvert@value[
				!names(coverconvert@value) %in% skip_scale]
		coverconvert@conversion <- coverconvert@conversion[
				!names(coverconvert@conversion) %in% skip_scale]
	}
	cover_match <- read.dbf(cover_home, as.is=TRUE)[,c("SCALE_NR","SCALE_NAME",
                    "SCALE_CODE")]
    cover_match$SCALE_CODE <- tolower(sub("/", "_", cover_match$SCALE_CODE,
                    fixed=TRUE))
    cover_code <- samples[,c("ReleveID","COVER_CODE")]
    cover_code$entry <- as.numeric(row.names(samples))
    cover_code <- split(cover_code, header$COVERSCALE[match(samples$ReleveID,
                            header$ReleveID)])
    for(i in names(cover_code)) {
        samples[,cover_match[cover_match$SCALE_NR == i,"SCALE_CODE"]] <-
                cover_code[[i]][match(as.numeric(rownames(samples)),
                                cover_code[[i]]$entry),"COVER_CODE"]
    }
    # Get percentage to numeric
    cover_code <- cover_match[cover_match$SCALE_NR == "00","SCALE_CODE"]
    if(cover_code %in% colnames(samples))
        samples[,cover_code] <- as.numeric(samples[,cover_code])
    for(i in slotNames(coverconvert)) slot(coverconvert, i) <-
                slot(coverconvert, i)[names(slot(coverconvert, i)) !=
                                cover_code]
    # Factorize
    cover_code <- names(coverconvert)[names(coverconvert) != cover_code]
    for(i in cover_code) {
        if(i %in% colnames(samples)) samples[,i] <- factor(samples[,i],
                    levels=levels(coverconvert@value[[i]]))
    }
    # Importing relations ------------------------------------------------------
    if(is.na(description["dictionary"])) {
        relations_path <- file.path(tv_home, "popup")
    } else relations_path <- file.path(tv_home, "popup",
                description["dictionary"])
    Files <- list.files(relations_path, pattern=".dbf", ignore.case=TRUE)
    Files <- Files[!toupper(Files) %in% c("dbasedic.dbf","files.dbf",
                    "tvscale.dbf")]
    relations <- list()
    for(i in Files) {
        relations[[tolower(i)]] <- read.dbf(file.path(relations_path, i),
                as.is=TRUE)
    }
    # some changes are needed in the standard relations
    colnames(relations$country.dbf)[1:2] <- c("COUNTRY","COUNTRY_NAME")
    colnames(relations$syntaxa.dbf)[1:2] <- c("SYNTAXON","SYNTAXON_NAME")
    colnames(relations$tvauthor.dbf)[1] <- c("AUTHOR")
    # Next cases have to be reformatted
    relations$tvauthor.dbf[,1] <- as.integer(relations$tvauthor.dbf[,1])
    relations$tvprojct.dbf[,1] <- as.integer(relations$tvprojct.dbf[,1])
    relations$tvrefenc.dbf[,1] <- as.integer(relations$tvrefenc.dbf[,1])
    relations$syntaxa.dbf[,1] <- as.integer(relations$syntaxa.dbf[,1])
    # Deleting empty relations
	if(skip_empty_relations) relations <- relations[sapply(relations, nrow) > 0]
    # Rename relations as first column
    names(relations) <- sapply(sapply(relations, colnames), "[", 1)
    # Insert details of cover scales in relations
    relations[["COVERSCALE"]] <- cover_match
    colnames(relations[["COVERSCALE"]])[1] <- "COVERSCALE"
    # Final object
    VEG <- new("vegtable")
    VEG@description <- description
    VEG@samples <- samples
    VEG@header <- header
    VEG@species <- tv2taxlist(description["sp_list"], tv_home)
    VEG@coverconvert <- coverconvert
    for(i in names(relations)) {
        if(colnames(relations[[i]])[1] %in% colnames(VEG@header))
            veg_relation(VEG, i) <- relations[[i]]
    }
    if(clean) VEG <- clean(VEG)
    return(VEG)
}