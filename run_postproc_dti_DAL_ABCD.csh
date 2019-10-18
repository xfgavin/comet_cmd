#!/bin/csh

set ProjID = 'DAL_ABCD'
set infix = 'postproc_dti'
set cmd = '/usr/bin/nohup ~/bin/run_all_MMPS.sh'
set config = '~/ProjInfo/'$ProjID'/'$ProjID'_'$infix'_ProcSteps.csv'
set log = '~/logs/'$ProjID'_'$infix'.log'

mkdir -p ~/logs
#find /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/proc_dti/ -type l -delete
echo $config
$cmd -p $ProjID -s $infix -c $config > $log &
