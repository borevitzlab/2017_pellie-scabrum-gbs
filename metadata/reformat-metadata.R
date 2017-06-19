library(tidyverse)

expt = read.delim("original/experiment.tsv", stringsAsFactors=F) %>%
        extract(plate.name, into=c("plate.set", "plate.num"),
                regex="(GH|SAf).*Plate(\\d)", remove=F) %>%
        mutate(plate.code = paste0(plate.set, plate.num)) %>%
        select(-plate.set, -plate.num)


samp = read.csv("original/samples.csv", stringsAsFactors=F) %>%
    filter(plate.name %in% expt$plate.name) %>% # remove plates not run
    rename(accession=value)

barcodes = read.csv("original/barcode.csv", stringsAsFactors=F) %>%
    separate(value, c("R1Barcode", "R2Barcode"), sep='/', fill='right') %>%
    mutate(R1Barcode = sub(" ", "", R1Barcode),
           R2Barcode = sub(" ", "", R2Barcode))

pellie = samp %>%
    left_join(expt, by=c("plate.name"="plate.name")) %>%
    left_join(barcodes, by=c("BARCODE"="plate.name", "well"="well")) %>%
    mutate(anon.name = paste0(plate.code, well)) %>%
    rename(lane=SubmissionName) %>%
    select(anon.name, accession, lane, plate.name, plate.code, well, R1Barcode, R2Barcode)

writeaxe = function(DF, prefix='keyfiles/') {
    lane = unique(DF$lane)
    if (all(DF$R2Barcode == "")) {
        DF = DF[,c("R1Barcode", "anon.name")]
    } else {
        DF = DF[,c("R1Barcode", "R2Barcode", "anon.name")]
    }
    write.table(DF, paste0(prefix, lane,".axe"),
                sep='\t', quote=F, row.names=F, col.names=F)
    return(DF)
}

t = pellie %>%
    select(lane, anon.name, R1Barcode, R2Barcode) %>%
    group_by(lane) %>%
    do(writeaxe(.))

write.csv(pellie, "pellie-metadata.csv", row.names=F)
