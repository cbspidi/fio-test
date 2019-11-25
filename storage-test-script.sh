#!/bin/bash -u

#BS=('4k' '16k' '1m')
#TYPE=('read' 'write' 'randread' 'randwrite')
#IODEPTH=(64)
dt=$(date '+%d/%m/%Y %H:%M:%S')
BS=('4k' '8k')
TYPE=('read' 'write' 'randread' 'randwrite')
IODEPTH=(64)
JOBS_NO=(1 5)
OUTPUT='/tmp/fio.json'
BASE_CMD='fio -ioengine=libaio -direct=1 -invalidate=1 -size=14G -runtime=60 -group_reporting -name=fio --output-format=json'

rm -f $OUTPUT{}
echo $dt >> ${OUTPUT}

for blocksize in ${BS[@]}; do

        for rwtype in ${TYPE[@]}; do

                TMPIOPS=()
                TMPBW=()

                for iodepth in ${IODEPTH[@]}; do

			for jobs_no in ${JOBS_NO[@]}; do

                        TMPFILE=`mktemp`
                        ${BASE_CMD} -rw=${rwtype} -numjobs=${jobs_no} -bs=${blocksize} -iodepth=${iodepth} --output ${TMPFILE}
                        case ${rwtype} in
                                'read' )
                                        IOPS=`cat ${TMPFILE} | jq ."jobs[0].read.iops"`
                                        BW=`cat ${TMPFILE} | jq ."jobs[0].read.bw"`
                                        ;;
                                'randread' )
                                        IOPS=`cat ${TMPFILE} | jq ."jobs[0].read.iops"`
                                        BW=`cat ${TMPFILE} | jq ."jobs[0].read.bw"`
                                        ;;
                                'write' )
                                        IOPS=`cat ${TMPFILE} | jq ."jobs[0].write.iops"`
                                        BW=`cat ${TMPFILE} | jq ."jobs[0].write.bw"`
                                        ;;
                                'randwrite' )
                                        IOPS=`cat ${TMPFILE} | jq ."jobs[0].write.iops"`
                                        BW=`cat ${TMPFILE} | jq ."jobs[0].write.bw"`
                                        ;;
                        esac
                        TMPIOPS+=( ${IOPS} )
                        TMPBW+=( ${BW} )
                        rm -f ${TMPFILE}
                        sleep 6

                done
                echo "{\"blocksize\": \"${blocksize}\", \"rwtype\": \"${rwtype}\", \"iops\": [`echo ${TMPIOPS[@]} | tr -s ' ' ','`], \"bw\": [`echo ${TMPBW[@]} | tr -s ' ' ','`]}" >> ${OUTPUT}

        done
	done
done
