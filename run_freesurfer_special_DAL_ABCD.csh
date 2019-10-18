#!/bin/csh

set ProjID = 'DAL_ABCD'
set infix = 'freesurfer_special'
set cmd = '/usr/bin/nohup ~/bin/run_all_MMPS.sh'
set config = '~/ProjInfo/'$ProjID'/'$ProjID'_'$infix'_ProcSteps.csv'
set log = '~/logs/'$ProjID'_'$infix'.log'
set lckfile = ~/.lock-$ProjID-$infix

if ( -f $lckfile ) then
  echo "lock file exists"
else
  touch $lckfile
  mkdir -p ~/logs
  #find /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/fsurf/ -type l -delete
  $cmd -p $ProjID -s $infix -c $config > $log &
  rm $lckfile
endif
