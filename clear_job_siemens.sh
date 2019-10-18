#!/bin/bash
for jobid in `squeue -u xfgavin | grep " R " | awk '{print $1}'`
do
  siteid=`head -n1 batchdirs/DAL_ABCD_postproc_BOLD/pbsout/DAL_ABCD_postproc_BOLD-$jobid.out |cut -d_ -f3`
  echo $siteid
  [ ${siteid::1} = "S" ] && scancel $jobid
done
