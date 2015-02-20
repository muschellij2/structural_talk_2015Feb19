---
title: "Neuroimaging in R"
author: "John Muschelli"
date: "February 19, 2015"
output: ioslides_presentation
---



## Introduction: Packages

- oro.nifti: read/write data, the nifti object
- fslr: process data (need FSL for most of the fun)
- ANTsR: process data (need cmake)
- extrantsr: makes ANTsR easier (need ANTsR)

## Install these packages


```r
install.packages("oro.nifti")
install.packages("devtools")
devtools::install_github("stnava/ANTsR") # takes long
devtools::install_github("muschellij2/extrantsr")
devtools::install_github("muschellij2/fslr")
```


## Files

Multi-modal dataset from SuBLIME (thanks Elizabeth), raw and unprocessed (other than NIfTI conversion).  

- 4 modalities: T1,T2,PDF,FLAIR
- 2 time points Baseline and Followup




```r
files
```

```
                   base_t1                    base_t2 
   "01-Baseline_T1.nii.gz"    "01-Baseline_T2.nii.gz" 
                   base_pd                 base_flair 
   "01-Baseline_PD.nii.gz" "01-Baseline_FLAIR.nii.gz" 
                      f_t1                       f_t2 
   "01-Followup_T1.nii.gz"    "01-Followup_T2.nii.gz" 
                      f_pd                    f_flair 
   "01-Followup_PD.nii.gz" "01-Followup_FLAIR.nii.gz" 
```

## Read in the Files!

Let's read in the baseline T1.  The `readNIfTI` function is the workhorse:

```r
library(oro.nifti)
base_t1 = readNIfTI(files["base_t1"])
```



```r
base_t2 = readNIfTI(files["base_t2"])
```

```
Error in if (sum(T != 0) == 3 && det(T) != 0) {: missing value where TRUE/FALSE needed
```


```r
base_t2 = readNIfTI(files["base_t2"], reorient = FALSE)
```

## An aside on `reorient` in `readNIfTI`

Arguments for `readNIfTI`:

```r
args(readNIfTI)
```

```
function (fname, verbose = FALSE, warn = -1, reorient = TRUE, 
    call = NULL) 
NULL
```
The default is `reorient = TRUE` but this fails **a lot**, especially when the transformation matrix is not diagonal.

##  {.flexbox .vcenter}
<div style='font-size: 35pt;'>
Use ``reorient=FALSE``
</div>

## Quick Plots


```r
orthographic(base_t1)
```

![plot of chunk ortho2](figure/ortho2-1.png) 

## Quick Plots


```r
library(fslr)
fslr::ortho2(base_t1, mfrow= c(1, 3), add.orient = FALSE)
```

![plot of chunk ortho](figure/ortho-1.png) 

## Creating new nifti objects

Use `niftiarr` to create new `nifti` objects from old one:

```r
quantile(c(base_t1[base_t1 > 0]), prob=0.75)
```

```
75% 
 26 
```

```r
mask = base_t1 >= 26 & base_t1 < 100
class(mask)
```

```
[1] "array"
```

```r
mask = niftiarr(base_t1, base_t1 >= 26 & base_t1 < 100)
class(mask)
```

```
[1] "nifti"
attr(,"package")
[1] "oro.nifti"
```

```r
ortho2(mask)
```

![plot of chunk cal_img](figure/cal_img-1.png) 



## Skull Stripping

Using FSL BET for the baseline T1 image:


```r
library(fslr)
ss_t1 = fslbet(base_t1, retimg = TRUE, opts = "-f 0.1 -v", 
               betcmd = "bet2")
```

```
FSLDIR=/usr/local/fsl/; export FSLDIR; sh ${FSLDIR}/etc/fslconf/fsl.sh; FSLOUTPUTTYPE=NIFTI_GZ; export FSLOUTPUTTYPE; $FSLDIR/bin/bet2 "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpGGPv5v/file3eab17fc27fd.nii.gz" "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpGGPv5v/file3eab34bdc990" -f 0.1 -v 
```

- `fslbet` - the command
- `retimg` - Return an image
- `opts` - options of bash `bet` command
- `betcmd` - can use `bet2` or `bet` (wrapper for `bet2`)



## Bias Field Correction

```r
library(ANTsR)
```

```
Loading required package: Rcpp
Welcome to ANTsR
```

```r
library(extrantsr)
n3_t1 = bias_correct(file = base_t1, correction = "N3", retimg=TRUE)
n4_t1 = bias_correct(file = base_t1, correction = "N4", retimg=TRUE)
```
