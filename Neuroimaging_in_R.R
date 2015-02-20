## ----knit-setup, echo=FALSE, results='hide', eval=TRUE-------------------
rm(list=ls())
library(knitr)
setwd("~/Dropbox/neuroimagingforstatisticians/manuscript/structural_talk/")
options(fsl.path = "/usr/local/fsl/")
opts_chunk$set(cache = TRUE, comment = "")
hook1 <- function(x){ gsub("```\n*```r*\n*", "", x) }
hook2 <- function(x){ gsub("```\n+```\n", "", x) }
knit_hooks$set(document = hook2)

## ----, eval=FALSE--------------------------------------------------------
install.packages("oro.nifti")
install.packages("devtools")
devtools::install_github("stnava/ANTsR") # takes long
devtools::install_github("muschellij2/extrantsr")
devtools::install_github("muschellij2/fslr")

## ----, echo=FALSE--------------------------------------------------------
files = c(base_t1="01-Baseline_T1.nii.gz", 
          base_t2="01-Baseline_T2.nii.gz",
          base_pd="01-Baseline_PD.nii.gz", 
          base_flair="01-Baseline_FLAIR.nii.gz", 
          f_t1= "01-Followup_T1.nii.gz", 
          f_t2= "01-Followup_T2.nii.gz", 
          f_pd = "01-Followup_PD.nii.gz", 
          f_flair="01-Followup_FLAIR.nii.gz")

## ------------------------------------------------------------------------
files

## ----read_t1, message=FALSE----------------------------------------------
library(oro.nifti)
base_t1 = readNIfTI(files["base_t1"])

## ----read_t2_err, error=TRUE---------------------------------------------
base_t2 = readNIfTI(files["base_t2"])

## ----read_t2-------------------------------------------------------------
base_t2 = readNIfTI(files["base_t2"], reorient = FALSE)

## ------------------------------------------------------------------------
args(readNIfTI)

## ----ortho2, message=FALSE-----------------------------------------------
orthographic(base_t1)

## ----ortho, message=FALSE------------------------------------------------
library(fslr)
fslr::ortho2(base_t1, mfrow= c(1, 3), add.orient = FALSE)

## ----, message=FALSE-----------------------------------------------------
arr = base_t1 >= 40
class(arr)

## ----bad_cal_img, message=FALSE------------------------------------------
arr = base_t1 >= 40 & base_t1 < 60
class(arr)
mask = base_t1
mask@.Data = arr
class(mask)

## ----bad_cal_img_plot, message=FALSE-------------------------------------
ortho2(mask)

## ----cal_img, message=FALSE----------------------------------------------
mask = cal_img(mask)
ortho2(mask)

## ----, error = TRUE------------------------------------------------------
mask@.Data[5] = 3
writeNIfTI(mask, filename = tempfile())

## ----niftiarr, message=FALSE---------------------------------------------
mask = niftiarr(base_t1, base_t1 >= 40 & base_t1 < 60)
class(mask)

## ----niftiarr2, message=FALSE--------------------------------------------
ortho2(mask)

## ----bet-----------------------------------------------------------------
library(fslr)
ss_t1 = fslbet(base_t1, retimg = TRUE, opts = "-f 0.1 -v", 
               betcmd = "bet2", outfile = "Brain_Mask")

## ----overlay, message=FALSE----------------------------------------------
library(scales)
mask = cal_img(ss_t1 > 0)
mask[mask == 0] = NA
ortho2(base_t1, y=mask, col.y=alpha("red", 0.5))

## ------------------------------------------------------------------------
library(ANTsR)
library(extrantsr)
n3_t1 = bias_correct(file = base_t1, correction = "N3", retimg=TRUE)
n4_t1 = bias_correct(file = base_t1, correction = "N4", retimg=TRUE)

## ----, eval=FALSE--------------------------------------------------------
reg_base_t2 = ants_regwrite(filename = files["base_t2"],  
                            template.file = files['base_t1'],
                            retimg= TRUE,
                            typeofTransform = "Rigid", 
                            remove.warp = TRUE)

## ----, eval=FALSE--------------------------------------------------------
proc_images = preprocess_mri_within(
  files = files[c("base_t1", "base_t2", "base_pd", "base_flair")],
    retimg = TRUE, maskfile = "Brain_Mask.nii.gz")

## ----, eval=FALSE--------------------------------------------------------
outfiles = gsub("[.]nii", '_process.nii', files)
preprocess_mri_across(
  baseline_files = files[c("base_t1", "base_t2", "base_pd", "base_flair")],
    followup_files = files[c("f_t1", "f_t2", "f_pd", "f_flair")],
    baseline_outfiles = outfiles[c("base_t1", "base_t2", "base_pd", "base_flair")],
    followup_outfiles = outfiles[c("f_t1", "f_t2", "f_pd", "f_flair")],
  maskfile = "Brain_Mask.nii.gz")

