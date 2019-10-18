#!/bin/bash

usage(){
echo "Usage:"
exit 0
}

while getopts "s:e:o:r:j:p:" OPTION
do
     case $OPTION in
         s)
             SCRATCHROOT=$OPTARG
             ;;
         j)
             JOB=$OPTARG
             ;;
         r)
             RUNSCRIPT=$OPTARG
             ;;
         o)
             OUTPUT=$OPTARG
             ;;
         e)
             ERROR=$OPTARG
             ;;
         p)
             PARMS=$OPTARG
             ;;
         ?)
             usage
             ;;
     esac
done

if [[ -z $SCRATCHROOT ]]; then
     echo "Please specify scratchroot"
     usage
fi
if [[ -z $RUNSCRIPT ]]; then
     echo "Please specify runscript"
     usage
fi
if [[ -z $OUTPUT ]]; then
     echo "Please specify output file"
     usage
fi
if [[ -z $ERROR ]]; then
     echo "Please specify error file"
     usage
fi

SINGULARITYENV_SCRATCHROOT=$SCRATCHROOT /opt/singularity/bin/singularity shell -B /home/xfgavin/RH4-x86_64-R530:/usr/pubsw/packages/freesurfer/RH4-x86_64-R530 --cleanenv /oasis/scratch/comet/xfgavin/temp_project/singularity/MMPS.img -c "/bin/tcsh -c \"($RUNSCRIPT `echo $PARMS` >$OUTPUT) >& $ERROR\""
