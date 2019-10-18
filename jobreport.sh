#!/bin/bash
USER=`whoami`
SCRIPTROOT=$( cd $(dirname $0) ; pwd)

target=$1
procroot=/oasis/scratch/comet/$USER/temp_project/ABCD/DAL_ABCD/

case $target in
  proc_dti)
    jobname=postproc_DTI
    ;;
  proc_bold)
    jobname=postproc_BOLD
    logfile=$HOME/logs/DAL_ABCD_$jobname.log
    lastlogpos=`grep -n "startup_MMPS" $logfile|tail -n1|cut -d: -f1`
    job_done=`tail -n +$lastlogpos $logfile|grep "WARNING: postproc is finished"|wc -l`
    job_running=`squeue -u $USER|grep " postproc "|grep " R "|wc -l`
    job_pending=`squeue -u $USER | grep " postproc " | grep " PD "`
    job_lckfile=$HOME/.lock-DAL_ABCD-postproc_bold
    ;;
  fsurf)
    $SCRIPTROOT/clean_fsurf.sh
    jobname=freesurfer
    job_done=`ls $procroot/fsurf/*.tar|wc -l`
    job_running=`squeue -u $USER|grep " fsurf "|grep " R "|wc -l`
    job_pending=`squeue -u $USER | grep " fsurf " | grep " PD "`
    job_lckfile=$HOME/.lock-DAL_ABCD-freesurfer
    ;;
  *)
    ;;
esac

MSG="Dear All,\n\nPlease find Comet $jobname job status below.\n\nThis email will be sent daily at 8am.\nPlease let me (xfgavin@gmail.com) know if you want to be removed from the list."
MSG="$MSG\n**************************************************************************"
MSG="$MSG\nWe have finished $jobname for $job_done subjects"

[ ${#job_running} -gt 0 ] && MSG="$MSG\nThere are $job_running jobs running"

if [ ${#job_pending} -gt 0 ]
then
  jobrange_lower=`echo $job_pending|cut -d " " -f1|cut -d_ -f2|sed -e "s/\([|]\)//g" -e "s/-/ /g" | awk '{print $1}'`
  jobrange_upper=`echo $job_pending|cut -d " " -f1|cut -d_ -f2|sed -e "s/\([|]\)//g" -e "s/-/ /g" | awk '{print $2}'`
  MSG="$MSG\nThere are also $((jobrange_upper-jobrange_lower)) jobs in pending state"
else
  MSG="$MSG\nThere is no job in pending state"
fi

[ -f $job_lckfile ] && MSG="$MSG\nThe job creator is still running."

SU_quota=`/opt/sdsc/bin/show_accounts.pl | grep $USER|awk '{print $4}'`
SU_used=`/opt/sdsc/bin/show_accounts.pl | grep $USER|awk '{print $5}'`

MSG="$MSG\n\nNow we have used $SU_used of $SU_quota SUs"

disk_used=`lfs quota -u $USER /oasis/scratch/comet|tail -n1|awk '{print $1}'`
disk_quota=`lfs quota -u $USER /oasis/scratch/comet|tail -n1|awk '{print $3}'`
disk_used=`echo "$disk_used/1024/1024/1024"|bc`
disk_quota=`echo "$disk_quota/1024/1024/1024"|bc`
MSG="$MSG\nNow we have used ${disk_used}T of ${disk_quota}T on oasis@comet"
MSG="$MSG\n**************************************************************************"

#echo -e $MSG | mail -s "Comet $jobname job status report" xfgavin@gmail.com,dhagler@mail.ucsd.edu,andersmdale@gmail.com,hbartsch@ucsd.edu
echo -e $MSG | mail -s "Comet $jobname job status report" xfgavin@gmail.com
