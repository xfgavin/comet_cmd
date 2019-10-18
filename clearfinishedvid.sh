#!/bin/bash
cd /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/proc_bold/
for tar in *.tar
do
  vid=`echo $tar|cut -d_ -f2-4`
  matcount=`tar tf $tar --wildcards "*ContainerInfo.mat"|wc -l` 
  [ $matcount -ne 1 ] && grep $vid ~/ProjInfo/DAL_ABCD/DAL_ABCD_VisitInfo.csv >> ~/ProjInfo/DAL_ABCD/DAL_ABCD_VisitInfo.csv.checkcontainerinfo && continue
  matcount=`tar tf $tar --wildcards "*.mat"|wc -l`
  [ $matcount -gt 1 ] && sed /$vid/d -i ~/ProjInfo/DAL_ABCD/DAL_ABCD_VisitInfo.csv && continue
done 
