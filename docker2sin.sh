#!/bin/bash
cd /oasis/scratch/comet/xfgavin/temp_project/singularity/
img=mmps_`date '+%Y%m%d'`.img
/opt/singularity/bin/singularity image.create -s 30000 $img
/opt/singularity/bin/singularity image.import $img -f $1
