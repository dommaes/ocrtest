#!/bin/bash
RUNS=$1
RUNNR=1
RUNDIR=run
OUTPUT=result
FORMAT=txt
TESTPATH=$RUNDIR$RUNNR
shift
TESTCASES=("$@")

# functions
prepare() {
	rm -r $RUNDIR*/
	rm $OUTPUT.$FORMAT
	for ((i=1;i<=$RUNS;i++)); do
		mkdir $RUNDIR$i;
		mkdir $RUNDIR$i/tesseract;
		mkdir $RUNDIR$i/ocrad;
		mkdir $RUNDIR$i/ocropus;
	done
}

write_text() {
	echo $1 >> $OUTPUT.$FORMAT
}

write_timestamp() {
	TIMESTAMP=$(date +%s)
	echo $TIMESTAMP >> $OUTPUT.$FORMAT
}

write_time() {
	TIME=$[$2 - $1]
	write_text "TIME needed: "$TIME" seconds"
}

write_begin() {
	write_text "BEGIN "$1
	write_testcase $2
	write_timestamp
}

write_end() {
	write_timestamp
	write_text "END "$1
}

write_testcase() {
	write_text "TESTCASE "$1
}

set_engine() {
	cp ~/.ocrfeeder/$1.xml ~/.ocrfeeder/preferences.xml
}

ocropus() {
	TC=$1
	TCN=${TC%%.*}
	BINPATH=ocropus_bin
	OPATH=$TESTPATH/ocropus
	write_begin $FUNCNAME $TCN
	BEGIN=$TIMESTAMP
	$BINPATH/ocropus-nlbin $TC -o $OPATH/$TCN -n
	$BINPATH/ocropus-gpageseg $OPATH/$TCN/????.bin.png -n --minscale 5.0
	$BINPATH/ocropus-rpred $OPATH/$TCN/????/??????.bin.png -n
	$BINPATH/ocropus-hocr $OPATH/$TCN/????.bin.png -o $OPATH/$TCN.html
	write_end $FUNCNAME
	END=$TIMESTAMP
	write_time $BEGIN $END
}

tesseract() {
	TC=$1
	TCN=${TC%%.*}
	set_engine "tesseract"
	OPATH=$TESTPATH/tesseract
	write_begin $FUNCNAME $TCN
	BEGIN=$TIMESTAMP
	ocrfeeder-cli -i $TC -o $OPATH/$TCN -f HTML
	write_end $FUNCNAME
	END=$TIMESTAMP
	write_time $BEGIN $END
}

ocrad() {
	TC=$1
	TCN=${TC%%.*}
	set_engine "ocrad"
	OPATH=$TESTPATH/ocrad
	write_begin $FUNCNAME $TCN
	BEGIN=$TIMESTAMP
	ocrfeeder-cli -i $TC -o $OPATH/$TCN -f HTML
	write_end $FUNCNAME
	END=$TIMESTAMP
	write_time $BEGIN $END
}

# preparations
prepare

for ((i=1;i<=$RUNS;i++)); do
	RUNNR=$i
	TESTPATH=$RUNDIR$RUNNR
	# write begin
	write_text "BEGIN run "$RUNNR

	# begin processing with ocropus
	for j in "${TESTCASES[@]}"; do
		# begin processing with ocropus
		ocropus $j
		# begin processing with ocrfeeder + tesseract
		tesseract $j
		# begin processing with ocrfeeder + ocrad
		ocrad $j
	done

	# write end
	write_text "END run "$RUNNR
done
