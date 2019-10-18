#!/bin/csh

cd $1

set job = `echo $2|sed -e 's/\.m$//g'`
set visitid = `echo $job|cut -d_ -f3,4`
set proj = $3
set scratchroot = $4
set dataroot_in = (`echo $5|sed -e "s/;/\n/g" -e "s/ /\n/g" | sort -u`)
set dataroot_out = (`echo $6|sed -e "s/;/\n/g" -e "s/ /\n/g" | sort -u`)
set USER = `whoami`
set prefix_data_in = ()
set prefix_data_out = ()
set PROJROOT = /oasis/scratch/comet/$USER/temp_project/ABCD/$proj

set in_idx = 1
while ($in_idx <= $#dataroot_in)
  set out_idx = 1
  while ($out_idx <= $#dataroot_out)
    if ( $dataroot_in[$in_idx] == $dataroot_out[$out_idx] ) then
      set dataroot_in[$in_idx] = ""
      break
    endif
    @ out_idx++
  end
  @ in_idx++
end
set dataroot_in = `echo $dataroot_in| sed 's/ /\n/g' | sort -u`

foreach dir ($dataroot_in)
  switch ($dir)
    case proc:
      set prefix = "MRIPROC_"
      breaksw
    case proc_dti:
      set prefix = "DTIPROC_"
      breaksw
    case proc_bold:
      set prefix = "BOLDPROC_"
      breaksw
    case raw:
      set prefix = "MRIRAW_"
      breaksw
    case fsurf:
      set prefix = "FSURF_"
      breaksw
    default:
      echo "Wrong dataroot_in value"
      exit -1
  endsw
  set prefix_data_in = ($prefix_data_in $prefix)
end
foreach dir ($dataroot_out)
  switch ($dir)
    case proc:
      set prefix = "MRIPROC_"
      breaksw
    case proc_dti:
      set prefix = "DTIPROC_"
      breaksw
    case proc_bold:
      set prefix = "BOLDPROC_"
      breaksw
    case raw:
      set prefix = "MRIRAW_"
      breaksw
    case fsurf:
      set prefix = "FSURF_"
      breaksw
    default:
      echo "Wrong dataroot_out value"
      exit -1
  endsw
  set prefix_data_out = ($prefix_data_out $prefix)
end

set dir_idx = 1
while ($dir_idx <= $#dataroot_in)
  set data_in = `find $PROJROOT/$dataroot_in[$dir_idx] -name "$prefix_data_in[$dir_idx]${visitid}*.tar"`
  set data_in_exists = `echo $data_in | awk '{print length($0)}'`
  if ( $data_in_exists == 0 ) then
  
    set fname_dir_in = `find $PROJROOT/$dataroot_in[$dir_idx] -name "$prefix_data_in[$dir_idx]${visitid}*"`
    set fname_dir_in = `basename $fname_dir_in`
    set data_in_dir_exists = `echo $fname_dir_in | awk '{print length($0)}'`
    if ( $data_in_dir_exists == 0 ) then
      echo "Can't find input directory or file for $prefix_data_in[$dir_idx]${visitid} under $PROJROOT/$dataroot_in[$dir_idx]"
      exit -1
    endif
    switch ($dataroot_in[$dir_idx])
      case fsurf:
        if ( ! -d $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in/surf) then
          echo "Empty input directory: $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in"
          exit -1
        endif
        breaksw
    endsw
    if (-l $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in) then
      echo "another job is running"
      exit 0
    endif
  
  else
    set fname_dir_in = `basename $data_in|sed -e 's/\.tar$//g'`
#    if (-l $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in) then
#      echo "another job is running"
#      exit 0
#    endif
#    rm -rf $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in
    if ( -d $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in) then
      switch ($dataroot_in[$dir_idx])
        case fsurf:
          if ( ! -d $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in/surf) then
            rm -rf $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in
            tar xf $data_in -C $PROJROOT/$dataroot_in[$dir_idx]
          endif
          breaksw
      endsw
    else
      tar xf $data_in -C $PROJROOT/$dataroot_in[$dir_idx]
    endif
#    ln -s $scratchroot/$fname_dir_in $PROJROOT/$dataroot_in[$dir_idx]/$fname_dir_in
  endif
  @ dir_idx++
end

if (! $?fname_dir_in) then
  set data_out = `find $PROJROOT/$dataroot_out[1] -name "$prefix_data_out[1]${visitid}*.tar"`
  set data_out_exists = `echo $data_out | awk '{print length($0)}'`
  if ( $data_out_exists == 0 ) then
    set fname_dir_out = `find $PROJROOT/$dataroot_out[1] -name "$prefix_data_out[1]${visitid}*"`
    set data_out_dir_exists = `echo $fname_dir_out | awk '{print length($0)}'`
    if ( $data_out_dir_exists == 0 ) then
      echo "Can't find input directory or file for $prefix_data_out[1]${visitid} under $PROJROOT/$dataroot_out[1]"
      exit -1
    endif
    set fname_dir_in = `basename $fname_dir_out`
  else
    set fname_dir_in = `basename $data_out|sed -e 's/\.tar$//g'`
  endif
  set folderID = `echo $fname_dir_in |sed -e "s/$prefix_data_out[1]//g"`
else
  set folderID = `echo $fname_dir_in |sed -e "s/$prefix_data_in[$#prefix_data_in]//g"`
endif

set dir_idx = 1
set out_dirs = ()
while ($dir_idx <= $#dataroot_out)
  set fname_dir_out = $prefix_data_out[$dir_idx]$folderID
  set out_dirs = ($out_dirs $fname_dir_out)
  set need_tar_link = 1
  if (-l $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out) then
    echo "another job is running"
    exit 0
  endif
  if (-f $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out.tar) then
    if (-d $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out) then
      switch ($dataroot_out[$dir_idx])
        case fsurf:
          if (-d $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out/surf) then
            set need_tar_link = 0
          endif
          breaksw
        default:
          set need_tar_link = 0
          breaksw
      endsw
    endif
    if ( $need_tar_link == 1) then
      tar xf $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out.tar -C $scratchroot
      ln -s $scratchroot/$fname_dir_out $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out
    endif
  else if (-d $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out) then
    set need_tar_link = 0
    switch ($dataroot_out[$dir_idx])
      case fsurf:
        if (! -d $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out/surf) then
          set need_tar_link = 1
          mkdir -p $scratchroot/$fname_dir_out/touch
          touch $scratchroot/$fname_dir_out/touch/fs.finish.all.touch
          cp -a $PROJROOT/fsurf/$fname_dir_out/* $scratchroot/$fname_dir_out/
          rm -rf $PROJROOT/fsurf/$fname_dir_out
          ln -s $scratchroot/$fname_dir_out $PROJROOT/fsurf/$fname_dir_out
        endif
        breaksw
    endsw
  else
    mkdir -p $scratchroot/$fname_dir_out
    ln -s $scratchroot/$fname_dir_out $PROJROOT/$dataroot_out[$dir_idx]/$fname_dir_out
  endif

  @ dir_idx++
end

matlab -nodesktop -nosplash -r "$job"

set dir_idx = 1
while ($dir_idx <= $#out_dirs )
  #rm -rf $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar
  if (-l $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx]) then
    #tar cf $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar.tmp -C $scratchroot $out_dirs[$dir_idx]
    tar cf $scratchroot/$out_dirs[$dir_idx].tar -C $scratchroot $out_dirs[$dir_idx]
    mv $scratchroot/$out_dirs[$dir_idx].tar $PROJROOT/$dataroot_out[$dir_idx]/
    touch $PROJROOT/$dataroot_out[$dir_idx]/.finished_$out_dirs[$dir_idx]
    rm -rf $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx]
    #mv $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar.tmp $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar
    #touch $PROJROOT/$dataroot_out[$dir_idx]/.finished_$out_dirs[$dir_idx]
#    switch ($dataroot_out[$dir_idx])
#      case fsurf:
#        mkdir -p $PROJROOT/$dataroot_out/$fname_dir_out/touch
#        touch $PROJROOT/$dataroot_out/$fname_dir_out/touch/fs.finish.all.touch
#        breaksw
#    endsw
  else
    tar cf $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar.tmp -C $PROJROOT/$dataroot_out[$dir_idx] $out_dirs[$dir_idx]
    rm -rf $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx]
    mv $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar.tmp $PROJROOT/$dataroot_out[$dir_idx]/$out_dirs[$dir_idx].tar
    touch $PROJROOT/$dataroot_out[$dir_idx]/.finished_$out_dirs[$dir_idx]
#    switch ($dataroot_out[$dir_idx])
#      case fsurf:
#        mkdir -p $PROJROOT/$dataroot_out/$fname_dir_out/touch
#        touch $PROJROOT/$dataroot_out/$fname_dir_out/touch/fs.finish.all.touch
#        breaksw
#    endsw
  endif

  @ dir_idx++
end
