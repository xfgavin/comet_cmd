#!/bin/bash
#
# Run multiple MMPS processing and analysis steps
# The script waits for jobs to be finished.
# Usage:
#    /usr/bin/nohup run_all_MMPS.sh -p PROJID > log.txt &
#    run_all_MMPS.sh
#
# Created:  07/22/13 by Hauke Bartsch
# Prev Mod: 01/26/17 by Don Hagler
# Last Mod: 11/08/17 by Feng Xue
#

usage()
{
cat <<EOF
usage: $0 options

This script will run a series of processing steps as defined in a configuration script.
In order to work this script needs to run until the end of all processing steps. Use
nohup (or screen) to be able to disconnect from the shell (see example).

OPTIONS:
   -p      project name (e.g. PING)
   -s      suffix (e.g. proc)
   -m      cluster to use (optional, default is mmilcluster4)
   -f      force restart (removes the lock file)
   -c      configuration file to use (optional)
   -l      do not run anything, just print what would be done

Example:
  /usr/bin/nohup `basename $0` -p PING -m mmilcluster4 > log.txt &

EOF
exit 0
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
getValue=$DIR/getValue.sh

proj=
suffix=
cluster=mmilcluster4
force=0
testrun=0
configuration=
defaultconfiguration=$DIR/../parms/default_ProcSteps.csv
re_number='^[0-9]+$'
USERID=`whoami`
##################################
#Determine if is under slurm env.
##################################
testslurm=`which squeue`
if [ ${testslurm:0:1} = '/' ]
then
  isslurm=1
  SLURM_MAXARRAY=400 # Lower this or we can request dedicated nodes.
else
  isslurm=0
fi


while getopts "lfp:s:c:m:" OPTION
do
     case $OPTION in
         p)
             proj=$OPTARG
             ;;
         s)
             suffix=$OPTARG
             ;;
         m)
             cluster=$OPTARG
             ;;
         c)
             configuration=$OPTARG
             ;;
         f)
             force=1
             ;;
         l)
             testrun=1
             ;;
         ?)
             usage
             ;;
     esac
done

if [[ -z $proj ]]; then
     usage
fi

if [ ! -f "$configuration" ]; then
     conf=$HOME/ProjInfo/${proj}/${proj}_ProcSteps.csv
     if [ -e "$conf" ]; then
        configuration=$conf
     else
        configuration=$defaultconfiguration
     fi
     if [ -r "$configuration" ]; then
       echo "Using: $configuration"
     else
       echo "Error: could not find configuration file in $conf or $defaultconfiguration"
       exit 1
     fi
fi

if [ ! -r "$configuration" ]; then
   echo "Error: configuration file not readable ($configuration)"
   exit 1
fi

lockfile=$HOME/.lock-${proj}
if [ ! -z $suffix ]; then
  lockfile=${lockfile}-${suffix}
fi

if [ "$force" == "1" ]; then
  if [ -e "${lockfile}" ]; then
     echo "Warning: a lock file has been removed..."
     rm -f "${lockfile}"
  fi
fi

if [ -e "${lockfile}" ]
then
   echo "Error: lock file (${lockfile}) exists, last job might not be finished yet."
   echo "  If you are sure this is an error delete the lock file and try again."
   exit 0
else
   touch "${lockfile}"
fi

date

#
# define proj, batchname
# returns jobids string
#
function getJobIDs()
{
  d=`pwd`
  cd $HOME/batchdirs/${proj}_${batchname}/
  joblist=`cat scriptlist.txt`
  cd $d
  jobids=''
  for job in $joblist
  do
    jobids="$jobids ${job}"
  done
}

#
# define proj, exam, jobids
# returns once jobs are done
function waitForJobs()
{
  while [ 1 = 1 ]
  do
    sleep 10
    stillworking=0
    valSum=`ssh ${cluster} qstat -r`
    if [ $? -ne 0 ]
    then
       sleep 5
       /bin/echo -ne "[try again]";
       valSum=`ssh ${cluster} qstat -r`
    fi
    for job in $jobids
    do
      #val=`ssh ${cluster} qstat -j ${proj}_${exam}_$job`
      val=`echo $valSum | grep ${proj}_${batchname}_$job`
      if [ "$val" != "" ]
      then
        stillworking=1
      fi
    done
    if [ "$stillworking" == 0 ]
    then
       printf "\n---------step is done---------\n"
       break
    else
       /bin/echo -ne ".";
    fi
  done
}

# now loop through all the jobs in [project name].csv
step=0
while [ 1 ]; do
  T="$(date +%s)"
  parms=`$getValue ${configuration} parms $step`
  if [ $? -ne 0 ]
  then
     [ $isslurm -eq 1 ] && echo "last JobID: $jobid"
     break;
  fi

  command=`$getValue ${configuration} command $step`
  parms=$(echo $parms | sed -e "s/\${proj}/$stepname/g")
  #parms=$(echo $parms | sed -e "s/{/\\{/g")
  #parms=$(echo $parms | sed -e "s/}/\\}/g")
  parms=$(echo $parms | sed -e "s/\.\.\./\ /g")
  proc=`$getValue ${configuration} type $step`
  batchname=`$getValue ${configuration} batchname $step`
  clustercmd=`$getValue ${configuration} cluster $step`
  parms_job=`$getValue ${configuration} parms_job $step`
  dataroot_in=`$getValue ${configuration} dataroot_in $step`
  dataroot_out=`$getValue ${configuration} dataroot_out $step`

  echo "#"
  echo "# STEP $step ($command)"
  echo "#"

  if [ "$proc" == "matlab" ]; then
    if [ "${batchname}" != "" ]; then
       parms="${parms}; parms.batchname = [ '$batchname' ]"
    fi
    if [ "${parms}" == "" ]; then
       cmd="${command}('$proj');"
    else
       cmd="parms = []; ${parms}; args=mmil_parms2args(parms); ${command}('$proj', args{:});"
    fi

    if [ $testrun == "1" ]; then
       echo "matlab -nosplash -nojvm -r \"try $cmd exit; catch e; fprintf('ERROR in matlab: %s\n',e.message); exit; end;\""
    else
      if [ $isslurm -eq 1 ]; then
        jobstring=`date "+%Y%m%d%H%M%S"`_`$DIR/genRND.sh -l 10 -m`
        job_filename=$jobstring.csh
        job_sub_filename=${jobstring}_sub.sh
        mkdir -p $HOME/jobcache

cat <<JOBCACHE >$HOME/jobcache/$job_filename
#!/bin/csh
matlab -nodesktop -nosplash -nojvm -r "try $cmd exit; catch e; fprintf('ERROR in matlab: %s\n',e.message); exit; end;"
JOBCACHE

        chmod +x $HOME/jobcache/$job_filename
#SBATCH --res=ABCDRes
cat <<JOBCACHE >$HOME/jobcache/$job_sub_filename
#!/bin/bash
#SBATCH -D $HOME/logs # working directory
#SBATCH -J ${batchname}_sub # job name
#SBATCH -o ${proj}_${batchname}-%A.out   # Standard output and error log
#SBATCH -e ${proj}_${batchname}-%A.err   # Standard output and error log
#SBATCH -N 1 # number of nodes
#SBATCH -n 1 # number of cores
#SBATCH --mem=64G # memory pool for all cores
#SBATCH -p shared # partition
#SBATCH -t 1-00:00:00 # Max execution time
#srun /opt/singularity/bin/singularity shell --cleanenv /oasis/scratch/comet/$USERID/temp_project/singularity/MMPS.img -c "unset LS_COLORS;$HOME/jobcache/$job_filename >> $HOME/logs/${proj}_${batchname}.log"
srun /opt/singularity/bin/singularity shell --cleanenv /oasis/scratch/comet/$USERID/temp_project/singularity/MMPS.img -c "$HOME/jobcache/$job_filename >> $HOME/logs/${proj}_${batchname}.log"
JOBCACHE
        chmod +x $HOME/jobcache/$job_sub_filename
        if [ ${#jobid} -gt 0 ]; then
            jobid=`sbatch --dependency=afterany:$jobid $HOME/jobcache/$job_sub_filename 2>>$HOME/logs/${proj}_${batchname}.log|rev|cut -d" " -f1|rev`
        else
            jobid=`sbatch $HOME/jobcache/$job_sub_filename 2>>$HOME/logs/${proj}_${batchname}.log|rev|cut -d" " -f1|rev`
        fi
        [[ $jobid =~ $re_number ]] || $(echo "Slurm submission error"; rm -f "${lockfile}"; exit -1)
      else
          matlab -nosplash -nojvm -r "try $cmd exit; catch e; fprintf('ERROR in matlab: %s\n',e.message); exit; end;"
      fi
    fi
    if [ "${clustercmd}" == "" ]; then
       echo "no cluster run required..."
    else
       if [ $isslurm -eq 1 ]; then

          while [ ${#jobid} -gt 0 ]
          do
            status=`squeue -j $jobid 2>/dev/null|wc -l`
            if [ $status -gt 1 ]
            then
              (sleep 90; /bin/echo -ne ".")
            else
              break # Let's sleep longer or the system may complain.
            fi
          done
          jobid=""

          mkdir -p $HOME/batchdirs/${proj}_${batchname}/pbsout
          scriptlist=$HOME/batchdirs/${proj}_${batchname}/scriptlist.txt
          if [ -s $scriptlist ]; then
              jobcount=`wc -l $scriptlist|cut -d" " -f1`
              if [ ${#parms_job} -gt 1 ]; then
                partition=`echo $parms_job|cut -d ";" -f1`
                mem=`echo $parms_job|cut -d ";" -f2`
                node=`echo $parms_job|cut -d ";" -f3`
		NTask=`echo $parms_job|cut -d ";" -f4`
                NCPU=`echo $parms_job|cut -d ";" -f5`
                DUR=`echo $parms_job|cut -d ";" -f6`
              fi
              if [ ${#partition} -eq 0 ]; then
                if [ ${#DUR} -eq 0 ]; then
                  partition=debug
                  DUR=00:30:00
                else
                  if [ -z "${DUR##*-*}" ]; then
                    day=`echo $DUR|cut -d"-" -f1|sed -e "s/^0*//g"`
                    if [ ${#day} -gt 0 ]; then
                      partition=shared
                    else
                      hour=`echo $DUR|sed -e "s/^[^-]*-//g"|cut -d: -f1|sed -e "s/^0*//g"`
                      if [ ${#hour} -gt 0 ]; then
                        partition=shared
                      else
                        minute=`echo $DUR|sed -e "s/^[^-]*-//g"|cut -d: -f2|sed -e "s/^0*//g"`
                        if [ ${#minute} -gt 30 ]
                        then
                          partition=shared
                        else
                          partition=debug
                        fi
                      fi
                    fi
                  else
                    hour=`echo $DUR|sed -e "s/^[^-]*-//g"|cut -d: -f1|sed -e "s/^0*//g"`
                    if [ ${#hour} -gt 0 ]; then
                      partition=shared
                    else
                      minute=`echo $DUR|sed -e "s/^[^-]*-//g"|cut -d: -f2|sed -e "s/^0*//g"`
                      if [ ${#minute} -gt 30 ]
                      then
                        partition=shared
                      else
                        partition=debug
                      fi
                    fi
                  fi
                fi
              else
                [ ${#DUR} -eq 0 ] && [ $partition = debug ] && DUR=00:30:00 || DUR=1-00:00:00
                #TODO: add validation for DUR if partition & DUR both defined.
              fi
              [ ${#mem} -eq 0 ] && mem=16G  #add a test for the unit.
              [ ${#node} -eq 0 ] && node=1
              [ ${#NTask} -eq 0 ] && NTask=1
              [ ${#NCPU} -eq 0 ] && NCPU=1

              scriptlist_curr=`echo $scriptlist|sed -e "s/.txt//g"`_curr.txt
            
              for ((partid=1;partid<=$jobcount;partid++))
              do
                if [ $partid -gt 1 ]; then
                  queuecapacity=0
                  while [ $queuecapacity -lt 1 ]
                  do
                    queuecapacity=$SLURM_MAXARRAY
                    for pid in `cat $HOME/batchdirs/${proj}_${batchname}/.pids`
                    do
                      [ ${#pid} -eq 0 ] && continue
                      squeue -j $pid>$HOME/batchdirs/${proj}_${batchname}/.queuesnapshot
                      job_running=`grep ' R ' $HOME/batchdirs/${proj}_${batchname}/.queuesnapshot| wc -l`
                      job_pending=`grep ' PD ' $HOME/batchdirs/${proj}_${batchname}/.queuesnapshot| awk '{print $1}'|cut -d[ -f2|sed -e "s/]//g"`
                      [ $job_running -eq 0 -a ${#job_pending} -eq 0 ] && sed /$pid/d -i $HOME/batchdirs/${proj}_${batchname}/.pids && sleep 90 && continue
                      ((queuecapacity=queuecapacity-job_running))
                      if [ ${#job_pending} -gt 0 ]
                      then
                        job_pending_start=`echo $job_pending|cut -d- -f1`
                        job_pending_end=`echo $job_pending|cut -d- -f2`
                        ((queuecapacity=queuecapacity+job_pending_start-job_pending_end-1))
                      fi
                      [ $queuecapacity -lt 1 ] && sleep 90 && break
                      sleep 90
                    done
                  done
                else
                  queuecapacity=$SLURM_MAXARRAY
                  rm -f $HOME/batchdirs/${proj}_${batchname}/.pids
                fi
                ((jobpos_end=partid+queuecapacity-1))
                [ $jobpos_end -gt $jobcount ] && ((queuecapacity=jobcount-partid+1))

                sed -n $partid,$((partid+queuecapacity-1))p $scriptlist >$scriptlist_curr
                ((partid=partid+queuecapacity-1))
                jobstring=`date "+%Y%m%d%H%M%S"`_`$DIR/genRND.sh -l 10 -m`
                job_filename=$jobstring.sh
cat <<JOBCACHE >$HOME/jobcache/$job_filename
#!/bin/bash
#SBATCH -D $HOME/batchdirs/${proj}_${batchname}/pbsout # working directory 
#SBATCH -J ${batchname} # job name
#SBATCH -o ${proj}_${batchname}-%A_%a.out   # Standard output and error log
#SBATCH -e ${proj}_${batchname}-%A_%a.err   # Standard output and error log
#SBATCH -N $node # number of nodes
#SBATCH -n $NTask # number of task
#SBATCH -c $NCPU # number of cores
#SBATCH --mem=${mem} # memory pool for all cores
#SBATCH -p $partition # partition
#SBATCH -t $DUR # Max execution time
#SBATCH --array=1-$queuecapacity

file=\$1
job=\`sed -n "\${SLURM_ARRAY_TASK_ID}p" \$file\`
scratchroot=/scratch/$USERID/\$SLURM_JOB_ID
jobroot=\`dirname \$file\`
echo "Processing: \$job"
#srun /opt/singularity/bin/singularity shell -w /oasis/scratch/comet/$USERID/temp_project/singularity/MMPS.img -c "unset LS_COLORS;/bin/tcsh -c \"($HOME/bin/run_batchdir_${clustercmd}.csh \$jobroot \$job $proj \$scratchroot '$dataroot_in' '$dataroot_out' >$HOME/batchdirs/${proj}_${batchname}/pbsout/\$job.out) >& $HOME/batchdirs/${proj}_${batchname}/pbsout/\$job.err\""
srun $HOME/bin/singularity_wrapper.sh -s \$scratchroot -r $HOME/bin/run_batchdir_${clustercmd}.csh -p "\$jobroot \$job $proj \$scratchroot '$dataroot_in' '$dataroot_out'" -o $HOME/batchdirs/${proj}_${batchname}/pbsout/\$job.out -e $HOME/batchdirs/${proj}_${batchname}/pbsout/\$job.err
JOBCACHE
              chmod +x $HOME/jobcache/$job_filename
              jobid=`sbatch $HOME/jobcache/$job_filename $scriptlist_curr 2>>$HOME/logs/${proj}_${batchname}.log|rev|cut -d" " -f1|rev`
              if [[ $jobid =~ $re_number ]]; then
                echo -e "\njob: $jobid is submitted"
                echo $jobid >> $HOME/batchdirs/${proj}_${batchname}/.pids
              else
                echo "Slurm submission error"
                [ -e "${lockfile}" ] && rm -f "${lockfile}"
                exit -1
              fi
            done

            sleep 90

          else
            echo "$scriptlist is empty"
          fi
          printf "\n---------step is done---------\n"
       else
           if [ "${batchname}" == "" ]; then
              cmd="ssh ${cluster} ${clustercmd} $command"
           else
              cmd="ssh ${cluster} ${clustercmd} ${proj}_${batchname}"
           fi
           if [ "$testrun" == "1" ]; then
              echo $cmd
           else
              echo "now run $cmd"
              eval $cmd
              echo "did run $cmd"
           fi
       fi
    fi
    if [ "$testrun" == "0" -a "${clustercmd}" != "" -a $isslurm -eq 0 ]; then
       if [ "$batchname" == "" ]; then
          batchname=$command
       fi
       getJobIDs
       waitForJobs

       for u in `find $HOME/batchdirs/${proj}_${batchname}/pbsout/ -type f -name "*.err" -not -size 0`
       do
          echo "Check error log: $u"
       done
    fi
  else  # in case we do not have matlab run this using the 
    if [ "$testrun" == "1" ]; then
      echo "/usr/bin/env ${proc} ${command}"
    else
      /usr/bin/env ${proc} ${command}
    fi
  fi

  T="$(($(date +%s)-T))"
  echo "Timing (step $step): $T seconds"
  let step=step+1
done

if [ -e "${lockfile}" ]
then
   rm -f "${lockfile}"
else
   echo "Error: lock file (${lockfile}) could not be found at end of processing"
   echo " A lock file is created at the beginning of the process and needs to be"
   echo " removed at the end."
fi

date
