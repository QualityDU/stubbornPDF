#!/bin/bash

INPUT_PDF_FILE_PATH="$1";
OUTPUT_TXT_FILE_PATH="$2";

STUBBORNPDF_SESSION_RN="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)";
STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT="/tmp/temp-stubbornpdf-pdfimages-out-$STUBBORNPDF_SESSION_RN";
STUBBORNPDF_TEMP_DIR_TESSERACT_OUT="/tmp/temp-stubbornpdf-tesseract-out-$STUBBORNPDF_SESSION_RN";

function print_usage() {
    echo "=== stubbornPDF ===";
    echo "Usage: stubbornPDF.sh <INPUT_PDF_FILE_PATH> <OUTPUT_TXT_FILE_PATH>";
}

function bulk_ocr() {
    echo "Starting bulk OCR";
    local i=0;
    for ppm in "$STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT"/*; do
        echo "Processing $ppm...";
	local outname="tesser$i";
	echo "outname: $outname";
	tesseract "$ppm" "tesser$i" || { echo "Failed tesseract $ppm tesser$i. Quit"; exit 1; };
	i=$(( $i + 1 ));
    done;
    echo "Finished bulk OCR";
}

function res_collect() {
    echo -n > "$OUTPUT_TXT_FILE_PATH" || { echo "Failed to echo -n > $OUTPUT_TXT_FILE_PATH. Quit"; exit 1; };
    for txt in "$STUBBORNPDF_TEMP_DIR_TESSERACT_OUT"/*; do
        echo "Concatenating $txt ...";
	cat "$txt" >> "$OUTPUT_TXT_FILE_PATH";
    done;
}

if [ "$INPUT_PDF_FILE_PATH" = "" ]; then
    echo "Missing first argument.";
    print_usage;
    exit 1;
fi;
if [ "$OUTPUT_TXT_FILE_PATH" = "" ]; then
    echo "Missing second argument.";
    print_usage;
    exit 1;
fi;

if [ ! -f "$INPUT_PDF_FILE_PATH" ]; then
    echo "$INPUT_PDF_FILE_PATH is not a file. Quit";
    exit 1;
fi;
if [ -d "$OUTPUT_TXT_FILE_PATH" ]; then
    echo "$OUTPUT_TXT_FILE_PATH already exists as a directory. Quit";
    exit 1;
fi;
if [ -f "$OUTPUT_TXT_FILE_PATH" ]; then
    echo "$OUTPUT_TXT_FILE_PATH already exists as a file. Quit";
    exit 1;
fi;

INPUT_PDF_FILE_PATH="$(realpath "$INPUT_PDF_FILE_PATH")";
OUTPUT_TXT_FILE_PATH="$(realpath "$OUTPUT_TXT_FILE_PATH")";

mkdir "$STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT" || { echo "Failed to create directory $STUBBORNPDF_TEMP_DIR_PDFTOIMAGES_OUT. Quit"; exit 1; };

cd "$STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT" || { echo "Failed to cd $STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT. Quit"; exit 1; };

pdfimages "$INPUT_PDF_FILE_PATH" pdfimages-out || { echo "pdfimages process exited with $?. Quit"; exit 1; };

cd - || { echo "Failed to cd -"; exit 1; };
mkdir "$STUBBORNPDF_TEMP_DIR_TESSERACT_OUT" || { echo "Failed to create directory $STUBBORNPDF_TEMP_DIR_TESSERACT_OUT. Quit"; exit 1; };
cd "$STUBBORNPDF_TEMP_DIR_TESSERACT_OUT" || { echo "Failed to cd $STUBBORNPDF_TEMP_DIR_TESSERACT_OUT. Quit"; exit 1; };

bulk_ocr;

cd - || { echo "Failed to cd -"; exit 1; };
res_collect;

echo "Conversion finished. Freeing resources...";
rm -r "$STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT" || { echo "Failed to rm -r $STUBBORNPDF_TEMP_DIR_PDFIMAGES_OUT !"; exit 1; };
rm -r "$STUBBORNPDF_TEMP_DIR_TESSERACT_OUT" || { echo "Failed to rm -r $STUBBORNPDF_TEMP_DIR_TESSERACT_OUT !"; exit 1; };
echo "Done.";
