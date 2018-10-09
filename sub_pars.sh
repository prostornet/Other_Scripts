#!/bin/bash

# Base varibles
F_VC=vc_report.csv
F_SUB=sub_report.csv
F_2SUB=sub_double.csv
F_1SUB=sub_one.csv
F_NOSUB=sub_no.csv
TMPFILE1=$(mktemp)
#TMPFILE2=$(mktemp)

USAGE="\n\nUsage: $(basename "$0") <vc_report_[date].csv> <sub_report_[date].csv>\n\n\t- you should specify two files which we are going to parse as parametr\n\n"
if [ ! $# == 2 ]; then
   echo -e ${USAGE}
   exit 1
fi

#Fix export files
for i in $1 $2; do
   dos2unix ${i}
   sed -i '1,2d;s/"//g;s/,/;/g;s/.*/\L&/g' ${i}
done

mv -f $1 $(echo $1|sed -E 's/(^.([a-z]+)_([a-z]+))_([0-9]+)/\1/')
mv -f $2 $(echo $2|sed -E 's/(^.([a-z]+)_([a-z]+))_([0-9]+)/\1/')

#First step, checking file for double subscription
for srv in $(cut -d";" -f1 ${F_SUB} | uniq -d); do
   grep "^${srv}" ${F_SUB} >> ${F_2SUB}
   echo "" >> ${F_2SUB}
done

#Second step, single subscriptions
sort -t';' -k1,1 -u ${F_SUB} >> ${F_1SUB}

#Third step, we form file with server list that didn't have subscription
cut -d';' -f1 ${F_VC} | sort | grep -P -v '(^hcptwr-([0-9]+)|^cldtst([a-z0-9]+)|guest\ introspection)' >> ${TMPFILE1}

while read line; do
    result=`grep -E "^${line}" ${F_SUB}`
    if [[ -z ${result} ]]; then
      echo ${line}";No subscription" >> ${F_NOSUB}

     #else
       #echo "-- For server: "${line}" we have subscription: "${result}
       #echo "--"
    fi
done <${TMPFILE1}

#Finishing our scripts
rm -f ${TMPFILE1}
#rm -f ${TMPFILE2}

exit 0

 
