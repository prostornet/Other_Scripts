#!/bin/bash

# Base varibles
F_VC=vc_report.csv
F_SUB=sub_report.csv
F_2SUB=sub_double.csv
F_1SUB=sub_one.csv
TMPFILE1=$(mktemp)
TMPFILE2=$(mktemp)


#First step, checking file for double subscription
for srv in $(cut -d";" -f1 ${F_SUB} | uniq -d); do
   grep "^${srv}" ${F_SUB} >> ${F_2SUB}
   echo "" >> ${F_2SUB}
done

#Second step, single subscriptions
grep -F -v -f ${F_2SUB} ${F_SUB} >> ${TMPFILE2}
sort -t';' -k1,1 -u ${TMPFILE2} >> 0.${F_1SUB}
sort -t';' -k1,1 -u ${F_SUB} >> ${F_1SUB}

#
#cut -d';' -f1 ${FILE_VM} >> ${TMPFILE1}
#while read line
#do
#    result=`grep -E "^${line}" ${FILE_SUB}`
#    if [[ -z ${result} ]]; then
#      echo "-- NO subscription for server: "${line}
    #else
      #echo "-- For server: "${line}" we have subscription: "${result}
      #echo "--"
#    fi
#done <${TMPFILE1}


#Finishing our scripts
rm -f ${TMPFILE1}
rm -f ${TMPFILE2}

exit 0
