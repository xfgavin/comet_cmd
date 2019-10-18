#!/bin/bash
while [ 1 ]
          do
            status=`squeue -j $1 2>/dev/null`
            [ ${#status} -gt 1 ] && (sleep 10; /bin/echo -ne ".") || break
          done
