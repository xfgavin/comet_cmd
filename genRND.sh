#!/bin/bash
Usage(){
cat <<EOF
To generate certain length of random string.
Please remember, qstat can show 10 characters
Usage: genRND [-l LENGTH]
-l length

EOF
    exit 1

}

genRND(){
	case $TYPE in
		N)
			RNDPREFIX=$(cat /dev/urandom | tr -dc '0-9' | fold -w 32 | head -n 1)
			;;
		M)
			RNDPREFIX=$(cat /dev/urandom | tr -dc '0-9a-zA-Z' | fold -w 32 | head -n 1)
			;;
		*)
			RNDPREFIX=$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 32 | head -n 1)
			;;
	esac
	if [ $LEN -gt 0 ] ; then
		echo ${RNDPREFIX:0:$LEN}
	else
		echo $RNDPREFIX
	fi
}
LEN=0
TYPE=S
while [ x$1 != x ] ; do
		case $1 in
                        -l)
                                #length
                                [ "$2" = "" ] && Usage
                		LEN=$2
                                shift 2
                                ;;
                        -n)
                                #Output Numbers only
				TYPE=N
                                shift 1
                                ;;
                        -m)
                                #Mixed Output Numbers & Strings
				TYPE=M
                                shift 1
                                ;;
                        -s)
                                #Output Strings only
				TYPE=S
                                shift 1
                                ;;
                        *)
                                #Anything Else
                                EXTRAPARAMETER="$EXTRAPARAMETER $1"
                                shift 1
                                ;;
                esac

done
genRND
