## ---- message=F, warning=F-------------------------------------------------
library(TeMPO)
library(tidyverse)

theme_set(theme_light())

## --------------------------------------------------------------------------
# Sites
data("CAGE_clusters")

# Unstraded genome-wide signals as BigWigFiles
ChIP_Seq <- system.file("extdata", package = "TeMPO") %>%
    list.files(full.names=TRUE) %>%
    BigWigFileList()

names(ChIP_Seq) <- c("DNase", "H3K27ac", "H3K4me1", "H3K4me3")

# Stranded genome-wide signals as RleList
data("CAGE_plus")
data("CAGE_minus")

## --------------------------------------------------------------------------
promoters_only <- subset(CAGE_clusters, txType == "promoter")

SS1 <- tidyMetaProfile(sites = promoters_only, 
                      forward=ChIP_Seq$DNase, reverse=NULL,
                      upstream=1000, downstream=1000)

ggplot(SS1, aes(x=pos0, y=sense)) + 
    geom_line(alpha=0.75) +
    geom_vline(xintercept=0, alpha=0.75, linetype="dotted") +
    labs(x="Basepair position relative to center",
         y="Average DNase signal")

## --------------------------------------------------------------------------
enhancers_only <- subset(CAGE_clusters, clusterType == "enhancer")

SS2 <- tidyMetaProfile(sites = enhancers_only, 
                      forward=CAGE_plus$WT, reverse=CAGE_minus$WT,
                      upstream=300, downstream=300)

SS2 %>%
    gather(key="direction", value="score", sense, anti, factor_key=TRUE) %>%
    ggplot(aes(x=pos0, y=score, color=direction)) + 
    scale_color_brewer("Direction", palette="Set1") +
    geom_line(alpha=0.75) +
    geom_vline(xintercept=0, alpha=0.75, linetype="dotted") +
    labs(x="Basepair position relative to center",
         y="Average CAGE signal")

## --------------------------------------------------------------------------
SM <- tidyMetaProfile(sites = promoters_only, 
                      forward=ChIP_Seq, reverse=NULL,
                      upstream=1000, downstream=1000)

ggplot(SM, aes(x=pos0, y=sense, color=signal)) + 
    geom_line(alpha=0.75) +
    geom_vline(xintercept=0, alpha=0.75, linetype="dotted") +
    labs(x="Basepair position relative to center",
         y="Average CAGE signal")

## --------------------------------------------------------------------------
by_txType <- CAGE_clusters %>%
    subset(clusterType == "TSS" & txType %in% c("promoter", 
                                                "fiveUTR", 
                                                "proximal", 
                                                "intron")) %>%
    splitAsList(.$txType, drop=TRUE)

MS <- tidyMetaProfile(sites = by_txType, 
                      forward=ChIP_Seq$H3K27ac, reverse=NULL,
                      upstream=1000, downstream=1000)

ggplot(MS, aes(x=pos0, y=sense, color=sites)) + 
    geom_line(alpha=0.75) + 
    geom_vline(xintercept = 0, linetype="dotted", alpha=0.75) +
    scale_color_brewer("Genic Context", palette="Set2") +
    labs(x="Relative position from center", 
         y="Average H3K27ac Signal")

## --------------------------------------------------------------------------
by_clusterType <- split(CAGE_clusters, CAGE_clusters$clusterType)

MM1 <- tidyMetaProfile(sites = by_clusterType, 
                      forward=ChIP_Seq, reverse=NULL,
                      upstream=1000, downstream=1000)

ggplot(MM1, aes(x=pos0, y=sense, color=sites)) + 
    geom_line(alpha=0.75) + 
    facet_grid(signal~., scales="free_y") +
    labs(x="Relative position from center", 
         y="Average Signal")

## --------------------------------------------------------------------------
MM2 <- tidyMetaProfile(sites = by_clusterType, 
                      forward=CAGE_plus, reverse=CAGE_minus,
                      upstream=500, downstream=500)

MM2 %>%
    gather(key="direction", value="score", sense, anti, factor_key=TRUE) %>%
    ggplot(aes(x=pos0, y=score, color=direction)) + 
    geom_line(alpha=0.75) + 
    facet_grid(sites~signal, scales="free_y") +
    scale_color_brewer("Direction", palette="Set1") +
    labs(x="Relative position from center", 
         y="Average Signal")

## ----eval=FALSE------------------------------------------------------------
#  library(BiocParallel)
#  
#  # Set the backend to run calculations in series
#  register(SerialParam())
#  
#  # Set the backend to run parallelize calculations using i.e. 3 cores:
#  register(MulticoreParam(workers=3))

## --------------------------------------------------------------------------
# Recalculate the first example using medians
SS1_median <- tidyMetaProfile(sites = promoters_only, 
                      forward=ChIP_Seq$DNase, reverse=NULL,
                      upstream=1000, downstream=1000,
                      sumFun = matrixStats::colMedians)

# Merge the two profiles and plot
list(mean=SS1, median=SS1_median) %>% 
    bind_rows(.id="summary") %>%
    ggplot(aes(x=pos0, y=sense, color=summary)) +
    geom_line(alpha=0.75) +
    geom_vline(xintercept=0, alpha=0.75, linetype="dotted") +
    scale_color_discrete("Summary-function") +
    labs(x="Basepair position relative to center",
         y="Average DNase signal")

## --------------------------------------------------------------------------
# Recalculate the first example with different quantile trimmings:
SS1_95percent <- tidyMetaProfile(sites = promoters_only, 
                      forward=ChIP_Seq$DNase, reverse=NULL,
                      upstream=1000, downstream=1000,
                      trimUpper=0.95)

SS1_90percent <- tidyMetaProfile(sites = promoters_only, 
                      forward=ChIP_Seq$DNase, reverse=NULL,
                      upstream=1000, downstream=1000,
                      trimUpper=0.90)

# Merge the three profiles and plot
list(`100%`=SS1, 
     `95%`=SS1_95percent, 
     `90%`=SS1_90percent) %>% 
    bind_rows(.id="summary") %>%
    ggplot(aes(x=pos0, y=sense, color=summary)) +
    geom_line(alpha=0.75) +
    geom_vline(xintercept=0, alpha=0.75, linetype="dotted") +
    scale_color_discrete("Trimming-level") +
    labs(x="Basepair position relative to center",
         y="Average DNase signal")

## --------------------------------------------------------------------------
sessionInfo()

