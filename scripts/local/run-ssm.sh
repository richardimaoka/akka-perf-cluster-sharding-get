#!/bin/sh

# cd to the current directory as it runs other shell scripts
cd "$(dirname "$0")"

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# parse options, note that whitespace is needed (e.g. -c 4) between an option and the option argument
#  --seed-node-ipv4: The IPv4 address of the Akka Cluster seed node
#  --akka-http-ipv4: The IPv4 address of the Akka HTTP server
for OPT in "$@"
do
    case "$OPT" in
        '--seed-node-ipv4' )
            if [ -z "$2" ] ; then
                echo "option --seed-node-ipv4 requires an argument -- $1" 1>&2
                exit 1
            fi
            SEED_NODE_IPV4="$2"
            shift 2
            ;;
        '--akka-http-ipv4' )
            if [ -z "$2" ] ; then
                echo "option --akka-http-ipv4 requires an argument -- $1" 1>&2
                exit 1
            fi
            AKKA_HTTP_IPV4="$2"
            shift 2
            ;;
        -*)
            echo "illegal option -- '$(echo "$1" | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [ -n "$1" ] ; then
                EXEC_UUID="$1"
                break
            fi
            ;;
    esac
done

COMMAND_ERROR=""
if [ -z "$SEED_NODE_IPV4" ]; then
  COMMAND_ERROR="${COMMAND_ERROR}ERROR: --seed-node-ipv4 must be provided.\n"
elif [ -z "$AKKA_HTTP_IPV4" ]; then
  COMMAND_ERROR="${COMMAND_ERROR}ERROR: --akka-http-ipv4 must be provided.\n"
elif [ -z "$EXEC_UUID" ]; then
  COMMAND_ERROR="${COMMAND_ERROR}ERROR: the argument for test execution UUID must be provided.\n"
fi

if [ -n "${COMMAND_ERROR}" ]; then
  echo "${COMMAND_ERROR}" 1 >&2
  exit 1
fi
