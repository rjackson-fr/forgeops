#!/usr/bin/env bash
# Generate a set of kustomize base resources from the helm chart
#set -oe pipefail

# Grab our starting dir
start_dir=$(pwd)
# Figure out the dir we live in
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Bring in our standard functions
source $SCRIPT_DIR/stdlib.sh
cd $start_dir

usage() {
    exit_code=$1
    err=$2
    prog=$(basename $0)
    cat <<EOM
Usage: $prog [OPTIONS] ACTION RESTORE_TARGET

Generate a set of kustomize base resources from the helm chart. The script will
look through the kustomize/base directory for directories that have a values
file. It will run the helm chart with those values and output them to the
resources file.

  OPTIONS:
    -h|--help                        : display usage and exit
    --debug                          : enable debugging output
    --dryrun                         : do a dry run
    -v|--verbose                     : be verbose
    -f|--values ValuesFileName       : values file name to look for (default: $VALUES_FILE_DEF)
    -k|--kustomize KustomizePath     : path to kustomize dir (default: $KUSTOMIZE_BASE_DEF)
    -n|--namespace NAMESPACE         : namespace to work in
    -r|--resources ResourceFileName  : resource file name to output to (default: $RESOURCES_FILE_DEF)
    -V|--chartver ChartVersion       : version of the chart to use (default: $CHART_VER_DEF)

Requirements:
  * helm installed

Examples:
  Generate new base using defaults:
  $prog

  Generate using specific namespace:
  $prog -n stage

  Use custom values and resources files:
  $prog -f val.yml -r res.yml

  Use an alternate chart version:
  $prog -V 7.3

EOM

  if [ ! -z "$err" ] ; then
    echo "ERROR: $err"
    echo
  fi

  exit $exit_code
}

# Get the currently running service definition
processDir() {
  message "Starting processDir()" "debug"

  local dir=$1
  for d in $dir/* ; do
    [[ ! -d $d ]] && continue # Skip if not a dir

    if [ -f $d/$VALUES_FILE ] ; then
      message "Found $VALUES_FILE in ${d%*/}" "debug"
      local cwd=$(pwd)
      cd $d
      echo "Generating $d/$RESOURCES_FILE"
      runOrPrint "$HELM_CMD template $CHART/$CHART_NAME $HELM_OPTS -f $VALUES_FILE > $RESOURCES_FILE"
      cd $cwd
      processDir ${d%*/}
    else
      message "Didn't find $VALUES_FILE in ${d%*/}" "debug"
      processDir ${d%*/}
    fi
  done

  message "Finishing processDir()" "debug"
}

# Defaults
DEBUG=false
DRYRUN=false
VERBOSE=false

HELM_CMD=$(type -P helm)

CHART="oci://us-docker.pkg.dev/forgeops-public/charts"
CHART_NAME="identity-platform"
CHART_VER_DEF="7.4"
CHART_VER=
KUSTOMIZE_BASE_DEF=$SCRIPT_DIR/../kustomize/base
KUSTOMIZE_BASE=
NAMESPACE_DEF="prod"
NAMESPACE=
RESOURCES_FILE_DEF=resources.yaml
RESOURCES_FILE=
VALUES_FILE_DEF=values.yaml
VALUES_FILE=

while true; do
  case "$1" in
    -h|--help) usage 0 ;;
    --debug) DEBUG=true; shift ;;
    --dryrun) DRYRUN=true; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -f|--file) VALUES_FILE=$2; shift 2 ;;
    -k|--kustomize) KUSTOMIZE_BASE=$2; shift 2 ;;
    -n|--namespace) NAMESPACE=$2; shift 2 ;;
    -r|--resources) RESOURCES_FILE=$2; shift 2 ;;
    -V|--chartver) CHART_VER=$2; shift 2 ;;
    "") break ;;
    *) if [ -z $ACTION ] ; then
         ACTION=$1
         shift
       elif [ -z $TARGET ] ; then
         TARGET=$1
         shift
       else
         usage 1 "Unknown flag: $1"
       fi
       ;;
  esac
done

message "DEBUG=$DEBUG" "debug"
message "DRYRUN=$DRYRUN" "debug"
message "VERBOSE=$VERBOSE" "debug"

message "CHART=$CHART" "debug"
message "CHART_NAME=$CHART_NAME" "debug"

# Set variable defaults if not provided
CHART_VER=${CHART_VER:-$CHART_VER_DEF}
message "CHART_VER=$CHART_VER" "debug"
KUSTOMIZE_BASE=${KUSTOMIZE_BASE:-$KUSTOMIZE_BASE_DEF}
message "KUSTOMIZE_BASE=$KUSTOMIZE_BASE" "debug"
RESOURCES_FILE=${RESOURCES_FILE:-$RESOURCES_FILE_DEF}
message "RESOURCES_FILE=$RESOURCES_FILE" "debug"
VALUES_FILE=${VALUES_FILE:-$VALUES_FILE_DEF}
message "VALUES_FILE=$VALUES_FILE" "debug"
NAMESPACE=${NAMESPACE:-$NAMESPACE_DEF}
message "NAMESPACE=$NAMESPACE" "debug"

VERSION_OPT="--version $CHART_VER"
NAMESPACE_OPT="-n $NAMESPACE"
HELM_OPTS="$NAMESPACE_OPT $VERSION_OPT"

processDir "$KUSTOMIZE_BASE"
