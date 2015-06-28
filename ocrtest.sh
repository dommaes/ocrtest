#!/bin/bash

# Copyright 2015 Thomas Enderle
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# number of test runs
RUNS=$1
# run counter
RUNNR=1
# name of folder the ocr results will be stored in.
# the current run counter will be added.
RUNDIR=run
# name of file the needed time will be stored.
OUTPUT=result
# file extension of the output file
FORMAT=txt
# full foldername for the ocr results
TESTPATH=$RUNDIR$RUNNR
# discard the first call parameter
shift
# save the other parameters as an array
TESTCASES=("$@")

# functions
prepare() {
	# delete previous ocr results
	rm -r $RUNDIR*/
	# delete previous output
	rm $OUTPUT.$FORMAT
	# create one folder per run and one per engine in it
	for ((i=1;i<=$RUNS;i++)); do
		mkdir $RUNDIR$i;
		mkdir $RUNDIR$i/tesseract;
		mkdir $RUNDIR$i/ocrad;
		mkdir $RUNDIR$i/ocropus;
	done
}

# write text to output file
write_text() {
	echo $1 >> $OUTPUT.$FORMAT
}

# write current unix timestamp to output file
write_timestamp() {
	TIMESTAMP=$(date +%s)
	echo $TIMESTAMP >> $OUTPUT.$FORMAT
}

# calculate the difference of two timestamps and write it to output file
write_time() {
	TIME=$[$2 - $1]
	write_text "TIME needed: "$TIME" seconds"
}

# write begin and run counter to output file
write_begin() {
	write_text "BEGIN "$1
	write_testcase $2
	write_timestamp
}

# write end and run counter to output file
write_end() {
	write_timestamp
	write_text "END "$1
}

# write the name of the current testcase to output file
write_testcase() {
	write_text "TESTCASE "$1
}

# process ocr with ocropus
ocropus() {
	# current image file
	TC=$1
	# name of current testcase
	TCN=${TC%%.*}
	# path to ocropus binaries
	BINPATH=ocropy
	# output path
	OPATH=$TESTPATH/ocropus
	write_begin $FUNCNAME $TCN
	BEGIN=$TIMESTAMP
	# begin actual processing
	$BINPATH/ocropus-nlbin $TC -o $OPATH/$TCN -n
	$BINPATH/ocropus-gpageseg $OPATH/$TCN/????.bin.png -n --minscale 5.0
	$BINPATH/ocropus-rpred $OPATH/$TCN/????/??????.bin.png -n
	$BINPATH/ocropus-hocr $OPATH/$TCN/????.bin.png -o $OPATH/$TCN.html
	# end actual processing
	write_end $FUNCNAME
	END=$TIMESTAMP
	write_time $BEGIN $END
}

# process ocr with tesseract
tesseract_f() {
	TC=$1
	TCN=${TC%%.*}
	OPATH=$TESTPATH/tesseract
	write_begin $FUNCNAME $TCN
	BEGIN=$TIMESTAMP
	# begin actual processing
	tesseract $TC $OPATH/$TCN -l deu
	# end actual processing
	write_end $FUNCNAME
	END=$TIMESTAMP
	write_time $BEGIN $END
}

# process ocr with ocrad
ocrad_f() {
	TC=$1
	TCN=${TC%%.*}
	OPATH=$TESTPATH/ocrad
	write_begin $FUNCNAME $TCN
	BEGIN=$TIMESTAMP
	tifftopnm $TC | ocrad -o $OPATH/$TCN.txt
	write_end $FUNCNAME
	END=$TIMESTAMP
	write_time $BEGIN $END
}

# preparations
prepare

for ((i=1;i<=$RUNS;i++)); do
	RUNNR=$i
	TESTPATH=$RUNDIR$RUNNR
	write_text "BEGIN run "$RUNNR

	# begin processing
	for j in "${TESTCASES[@]}"; do
		# begin processing with ocropus
		ocropus $j
		# begin processing with ocrfeeder + tesseract
		tesseract_f $j
		# begin processing with ocrfeeder + ocrad
		ocrad_f $j
	done

	write_text "END run "$RUNNR
done
