#!/bin/csh

set ProjID = 'DAL_ABCD_syn18'
set infix = 'postproc_bold'
set cmd = '/usr/bin/nohup ~/bin/run_all_MMPS.sh'
set config = '~/ProjInfo/'$ProjID'/'$ProjID'_'$infix'_ProcSteps.csv'
set log = '~/logs/'$ProjID'_'$infix'.log'

mkdir -p ~/logs
set lckfile = $HOME/.lock-$ProjID-$infix
if ( -f $lckfile ) then
  echo "Lock file exists"
  exit 0
else
  touch $lckfile
endif
#find /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/proc_dti/ -type l -delete
$cmd -p $ProjID -s $infix -c $config > $log &
rm -f $lckfile
