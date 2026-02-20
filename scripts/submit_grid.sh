#!/bin/bash

# Simulation general configurations
EXPERIMENT=$(hostname | sed 's/gpvm*.*//')
CURRENT=176000
RUN_NUM=5
NSUBRUNS=1

# Submit a job to the grid
BASE_APP_DIR="/exp/${EXPERIMENT}/app/users/${USER}"
BASE_DATA_DIR="/pnfs/${EXPERIMENT}/scratch/users/${USER}/sbn/sbnd/bnb_horn"
EXE_FILE="$BASE_APP_DIR/bin/bnb_horn"
EXE_NAME=$(basename $EXE_FILE)
SCRIPT_DIR="$BASE_APP_DIR/share/sbn/sbnd/bnb_horn/scripts"
MACRO_DIR="$BASE_APP_DIR/share/sbn/sbnd/bnb_horn/macros"
MACRO_FILE="$MACRO_DIR/POT_100.mac"
MACRO_NAME=$(basename $MACRO_FILE)
OUTPUT_DATA_DIR="$BASE_DATA_DIR/run${RUN_NUM}"

# Ensure output directory exists, create if it doesn't
ifdh ls $OUTPUT_DATA_DIR >/dev/null 2>&1 || htgettoken -a htvaultprod.fnal.gov -i ${EXPERIMENT};ifdh mkdir_p $OUTPUT_DATA_DIR
OUTPUT_FILE="result_${RUN_NUM}_${SEED}_${CURRENT}.root"

echo "Preparing job assets ... "
ASSET_FILE_NAME="scripts_$(date +%Y%m%d_%H%M).tar.gz"
echo "Target: ${ASSET_FILE_NAME}"
echo "📦 Packing your scripts into a suitcase ($ASSET_FILE_NAME)..."
tar -cvzf $ASSET_FILE_NAME -C $BASE_APP_DIR/bin $EXE_NAME -C $MACRO_DIR $MACRO_NAME

if [ $? -ne 0 ]; then
    echo "Error: Failed to create tarball."
    exit 1
fi

ORIG_SIZE_BYTES=$(stat -c%s "$EXE_FILE" "$MACRO_FILE" | awk '{s+=$1} END {print s}')
ORIG_SIZE=$((ORIG_SIZE_BYTES / 1024))
COMP_SIZE=$(du -k "$ASSET_FILE_NAME" | awk '{print $1}')

echo "-------------------------------------------------------"
echo "✅ Tarball creation successful!"
echo "📊 Original size: ${ORIG_SIZE} KB"
echo "📊 Compressed size: ${COMP_SIZE} KB"
echo "📉 Compression ratio: $(awk "BEGIN {printf \"%.2f\", $COMP_SIZE/$ORIG_SIZE*100}")%"
echo "-------------------------------------------------------"

echo "🚀 Handing over the suitcase to the grid. -- Submitting Run $RUN_NUM with $NSUBRUNS subruns ... "

# Switch the token for the grid submission
echo "Switching to DUNE grid environment for job submission..."
echo "$ htgettoken -a htvaultprod.fnal.gov -i ${EXPERIMENT}"
htgettoken -a htvaultprod.fnal.gov -i ${EXPERIMENT}
SUBMIT_OUT=$(jobsub_submit -N $NSUBRUNS \
                            --memory=1000MB \
                            --disk=100MB \
                            --expected-lifetime=1h \
                            --group=${EXPERIMENT} \
                            --resource-provides=usage_model=OPPORTUNISTIC,DEDICATED \
                            -f dropbox://$EXE_FILE \
                            -f dropbox://$MACRO_FILE \
                            file://${SCRIPT_DIR}/agent.sh \
                            $EXE_NAME $MACRO_NAME $CURRENT $RUN_NUM $NSUBRUNS $BASE_DATA_DIR
                            2>&1)
JOB_ID=$(echo "$SUBMIT_OUT" | grep -oP '\d+\.\d+@jobsub\d+\.fnal\.gov' | cut -d'.' -f1)

if [ -z "$JOB_ID" ]; then
    echo "Error: Job submission failed or Job ID not captured."
    echo $SUBMIT_OUT
    exit 1
fi
echo "Success! Captured Job ID: $JOB_ID"

echo "⏳ Monitoring Job ID: $JOB_ID"
echo "Waiting for all sub-jobs to finish..."
sleep 360
while true; do
    # jobsub_q 결과에서 해당 Job ID가 포함된 라인 중 
    # 'I'(Idle), 'R'(Running), 'H'(Held) 상태가 있는지 확인
    ACTIVE_JOBS=$(jobsub_q --jobid=$JOB_ID 2>/dev/null | grep -E " I | R | H " | wc -l)

    if [ "$ACTIVE_JOBS" -eq 0 ]; then
        echo "🎉 All sub-jobs in $JOB_ID have completed!"
        break
    else
        echo "Status: $ACTIVE_JOBS jobs still active... ($(date +%H:%M:%S))"
        sleep 300  # 5분 간격으로 확인
    fi
done

echo "Switching to DUNE grid environment in interactive mode for data transfer..."
echo "$ htgettoken -a htvaultprod.fnal.gov -i ${EXPERIMENT} -r interactive"
htgettoken -a htvaultprod.fnal.gov -i ${EXPERIMENT}
PERSISTENT_OUT_DIR="${BASE_DATA_DIR/scratch/persistent}"

ifdh ls $PERSISTENT_OUT_DIR >/dev/null 2>&1 || ifdh mkdir_p $PERSISTENT_OUT_DIR

echo "Transferring results from scratch area to persistent storage..."
ifdh cp -D $OUTPUT_DATA_DIR/* $PERSISTENT_OUT_DIR/

echo "✅ Data transfer complete. Results are now in persistent storage at: $PERSISTENT_OUT_DIR"
ifdh cp -D $0 $PERSISTENT_OUT_DIR/
echo "📄 Script $0 has been copied to the persistent output directory for record-keeping."
echo "🎉 All tasks completed successfully!"
