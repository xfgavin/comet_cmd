#!/bin/bash
cd /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/fsurf/
for tar in `find . -name '*.tar' -size -250M`
do
  mv `echo $tar|sed -e "s/.tar//g"`* ../fsurf.bad/ >/dev/null 2>&1
  rm -rf `echo $tar|sed -e "s/.tar//g"`*
done
