#!/bin/bash

#source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
#source /cvmfs/larsoft.opensciencegrid.org/spack-packages/setup-env.sh
source /cvmfs/larsoft.opensciencegrid.org/spack-v0.22.0-fermi/setup-env.sh
ROOT_VER=6.28.12
IFDHC_VER=2.8.0
ARCH_SPEC="arch=linux-almalinux9-x86_64_v3"
COMPILER_SPEC="gcc@12.2.0"
spack load root@${ROOT_VER}%${COMPILER_SPEC} ${ARCH_SPEC}; if [ $? -eq 0 ] ; then echo "root ${ROOT_VER} loaded: location - $(spack location -i root@${ROOT_VER}%${COMPILER_SPEC} ${ARCH_SPEC})"; else echo "Failed to load root ${ROOT_VER}"; exit 1; fi
spack load ifdhc@${IFDHC_VER}%${COMPILER_SPEC} ${ARCH_SPEC}; if [ $? -eq 0 ] ; then echo "ifdhc ${IFDHC_VER} loaded: location - $(spack location -i ifdhc@${IFDHC_VER}%${COMPILER_SPEC} ${ARCH_SPEC})"; else echo "Failed to load ifdhc ${IFDHC_VER}"; exit 1; fi

RUN_NUM=$1
ANALYZER_SCRIPT_FILE=$2
USER=$3
SEED=$((RUN_NUM * 1000 + PROCESS))
INPUT_BASE_DIR="/pnfs/icarus/persistent/users/wyjang/sbn/sbnd/bnb_horn/run$RUN_NUM"
FULL_PATH=$(ifdh ls "$INPUT_BASE_DIR" | grep "result_${RUN_NUM}_${SEED}_" | head -n 1)
FILENAME=$(basename "$FULL_PATH")
MAG_FIELD=$(echo "$FILENAME" | cut -d'_' -f4 | sed 's/.root//')
XROOTD_URL="root://fndca1.fnal.gov:1094//pnfs/fnal.gov/usr/icarus/persistent/users/wyjang/icarus/bnb/horn/run$RUN_NUM/result_${RUN_NUM}_${SEED}_${MAG_FIELD}.root"
INPUT_FILE="${XROOTD_URL}"
OUTPUT_FILE="anaout_${RUN_NUM}_${SEED}_${MAG_FIELD}.root"
PNFS_DEST_DIR="/pnfs/icarus/scratch/users/$USER/sbn/sbnd/bnb_horn/run$RUN_NUM/anaout/"

cd ${CONDOR_DIR_INPUT}
time root -b -q -l "${ANALYZER_SCRIPT_FILE}(\"${INPUT_FILE}\", \"${OUTPUT_FILE}\")"

if [ -f "${OUTPUT_FILE}" ]; then
    echo "Transferring $OUTPUT_FILE to $PNFS_DEST_DIR ... "
    ifdh mkdir -p "${PNFS_DEST_DIR}"
    ifdh cp -D $OUTPUT_FILE $PNFS_DEST_DIR
else
    echo "Error: Output file $OUTPUT_FILE not found!"
    exit 1
fi
