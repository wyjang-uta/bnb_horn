#!/bin/bash

# This script submit analysis jobs using jobsub_submit command to the Fermilab grid cluster system.

RUN_NUM=8
NSUBRUNS=100
# Set the base directory
ABS_PATH="$(cd .. && pwd -P)"
ANALYZER_SCRIPT_FILE="$ABS_PATH/analyzer/bnb_plot.C"
echo $ABS_PATH
echo $ANALYZER_SCRIPT_FILE
USER=${USER}

jobsub_submit -N $NSUBRUNS \
    --memory=1000MB \
    --disk=100MB \
    --expected-lifetime=1h \
    --group=dune \
    --resource-provides=usage_model=OPPORTUNISTIC,DEDICATED \
    -f dropbox://$ANALYZER_SCRIPT_FILE \
    file://$ABS_PATH/scripts/agent_ana.sh \
    $RUN_NUM $(basename $ANALYZER_SCRIPT_FILE) $USER
