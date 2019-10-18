#!/bin/bash
USER=`whoami`
quota_SU=`/opt/sdsc/bin/show_accounts.pl | grep xfgavin|awk '{print $4}'`
usage_SU=`/opt/sdsc/bin/show_accounts.pl | grep xfgavin|awk '{print $5}'`
quota_SU_80=$((quota_SU*8/10))

[ $usage_SU -gt $quota_SU_80 ] && echo "SU usage: $usage_SU/$quota_SU" | mail -s "Comet SU quota exceeded 80%" xfgavin@gmail.com 

usage_disk=`lfs quota -u $USER /oasis/scratch/comet|tail -n1|awk '{print $1}'`
quota_disk=`lfs quota -u $USER /oasis/scratch/comet|tail -n1|awk '{print $3}'`
usage_disk=`echo "$usage_disk/1024/1024/1024"|bc`
quota_disk=`echo "$quota_disk/1024/1024/1024"|bc`
quota_disk_80=$((quota_disk*8/10))
[ $usage_disk -gt $quota_disk_80 ] && echo "Disk Usage: $usage_disk/$quota_disk" | mail -s "Comet disk quota exceeded 80%" xfgavin@gmail.com 
echo "SU usage: $usage_SU/$quota_SU"
echo "Disk usage: $usage_disk/$quota_disk"
