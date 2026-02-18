#!/bin/bash

SRC_DIR="/pnfs/dune/scratch/users/wyjang/dune/bnb/dipole"
DEST_DIR="${SRC_DIR}/run2"

# 카운팅 변수 초기화
TOTAL_COUNT=0
SUCCESS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0

echo "======================================================="
echo "  BNB_HORN Data Integrity Summary Report"
echo "  Start Time: $(date)"
echo "======================================================="

# 1. 파일 목록 가져오기
FILES=$(ifdh ls "$DEST_DIR" | grep ".root")

for DST_PATH in $FILES; do
    FILENAME=$(basename "$DST_PATH")
    SRC_PATH="${SRC_DIR}/${FILENAME}"
    ((TOTAL_COUNT++))

    # 2. 원본 파일 존재 확인
    if ! ifdh ls "$SRC_PATH" > /dev/null 2>&1; then
        echo "   [SKIP] $FILENAME : Original not found (already moved?)"
        ((SKIP_COUNT++))
        continue
    fi

    # 3. Checksum 비교
    SRC_HASH=$(ifdh checksum "$SRC_PATH" | awk '{print $1}')
    DST_HASH=$(ifdh checksum "$DST_PATH" | awk '{print $1}')

    if [ "$SRC_HASH" == "$DST_HASH" ] && [ -n "$SRC_HASH" ]; then
        echo "   [OK]   $FILENAME (Hash: $SRC_HASH)"
        ifdh rm "$SRC_PATH"
        if [ $? -eq 0 ]; then
            ((SUCCESS_COUNT++))
        else
            echo "   ⚠️ Warning: Match but failed to remove $FILENAME"
            ((FAILURE_COUNT++))
        fi
    else
        echo "   [FAIL] $FILENAME (Hash Mismatch!)"
        echo "          Src: $SRC_HASH | Dst: $DST_HASH"
        ((FAILURE_COUNT++))
    fi
done

# --- 최종 요약 출력 ---
echo ""
echo "======================================================="
echo "                 FINAL SUMMARY REPORT                  "
echo "======================================================="
echo "  📅 Date: $(date)"
echo "  📂 Total processed files:  $TOTAL_COUNT"
echo "  ✅ Integrity passed & RM:  $SUCCESS_COUNT"
echo "  🚨 Integrity failed/Error: $FAILURE_COUNT"
echo "  ⏭️  Already cleaned (Skip): $SKIP_COUNT"
echo "======================================================="

if [ $FAILURE_COUNT -eq 0 ] && [ $TOTAL_COUNT -gt 0 ]; then
    echo "🎉 Excellent! All files verified and cleaned up."
else
    echo "⚠️  Check failed files listed above."
fi
echo "======================================================="
