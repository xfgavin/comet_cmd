#!/bin/bash
sacct -j $1 -o 'JobID,JobName,MaxRSS,CPUTime,AllocCPUS,MaxVMSize,Elapsed'
