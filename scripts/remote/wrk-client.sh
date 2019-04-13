#!/bin/bash

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# default values
threads=4
connections=8
duration=30

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#  -c, --connections <N>  Connections to keep open
#  -d, --duration    <T>  Duration of test
#  -t, --threads     <N>  Number of threads to use
for OPT in "$@"
do
    case "$OPT" in
        '-c'|'--connections' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option -c or --connections requires an argument -- $1" 1>&2
                exit 1
            fi
            connections="$2"
            shift 2
            ;;
        '-d'|'--duration' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option -d or --duration requires an argument -- $1" 1>&2
                exit 1
            fi
            duration="$2"
            shift 2
            ;;
        '-t'|'--threads' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "wrk: option -t or --threads requires an argument -- $1" 1>&2
                exit 1
            fi
            threads="$2"
            shift 2
            ;;
        -*)
            echo "wrk: illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ -n "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                TARGET_URL="$1"
                break
            fi
            ;;
    esac
done

# Run wrk
# Using the --network host to reach out to other EC2 instances via their EC2 IPV4
# and mounting the current directory to wrk container's WORKDIR = '/data'
WRK_CMD="docker run --network host -v $(pwd):/data williamyeh/wrk -t ${threads} -c ${connections} -d ${duration} -s "wrk_script.lua" ${TARGET_URL}"
echo "running:"
echo "${WRK_CMD}"
${WRK_CMD}