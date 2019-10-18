#!/bin/csh
cd $1
set cmd = `ls ${2}*`
chmod +x $cmd
sed -e "s/recon-all -sd/recon-all -openmp 3 -sd/g" -i $cmd
./$cmd
