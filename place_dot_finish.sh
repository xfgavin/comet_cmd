#!/bin/bash
cd /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/fsurf/
for tar in `ls *.tar`
do
  touch .finished_`echo $tar|sed -e "s/.tar//g"`
done
