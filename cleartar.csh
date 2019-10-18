#!/bin/csh
cd /oasis/scratch/comet/xfgavin/temp_project/ABCD/DAL_ABCD/proc_bold/
foreach tar (*.tar)
  set matcount = `tar tf $tar --wildcards "*.mat"|wc -l`
 if ( $matcount == 0 ) then
 rm $tar
 echo $tar
 endif
 end
