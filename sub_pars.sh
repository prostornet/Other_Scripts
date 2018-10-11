#!/bin/bash

# Base varibles
D_BASE=/srv/www/subs/report_`date +%Y%m%d`
F_VC=vc_report.csv
F_SUB=sub_report.csv
F_2SUB=01_doublesub.csv
F_1SUB=02_onesub.csv
F_NOSUB=03_nosub.csv
F_OKSUB=04_oksub.csv
F_ERRH=05_errhdd.csv
F_ERRR=05_errram.csv
F_ERRC=05_errcpu.csv
F_ERR=00_err.csv
TMPFILE1=$(mktemp)


USAGE="\n\nUsage: $(basename "$0") <vc_report_[date].csv> <sub_report_[date].csv>\n\n\t- you should specify two files which we are going to parse as parametr\n\n"

if [ ! $# == 2 ]; then
   echo -e ${USAGE}
   exit 1
fi

for F in ${F_VC} ${F_SUB} ${F_2SUB} ${F_1SUB} ${F_NOSUB} ${F_OKSUB} ${F_ERRH} ${F_ERRR} ${F_ERRC} ${F_ERR}; do
   :>${F}
done


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

#Third step,
cut -d';' -f1 ${F_VC}| sort | grep -P -v '(^hcptwr-([0-9]+)|^cldtst([a-z0-9]+)|guest\ introspection)' >> ${TMPFILE1}
while read line; do
   result_sub=`grep -E "^${line}" ${F_SUB}`
   result_vc=`grep -E "^${line}" ${F_VC}`
   if [[ -z ${result_sub} ]]; then
      echo ${line}";No subscription" >> ${F_NOSUB}
   else
      vc_c=`echo ${result_vc}|awk -F';' '{print $2}'`
      vc_r=`echo ${result_vc}|awk -F';' '{print $3}'`
      vc_h=`echo ${result_vc}|awk -F';' '{print int($4)}'`

      sub_c=`echo ${result_sub}|awk -F';' '{print $2}'`
      sub_r=`echo ${result_sub}|awk -F';' '{print int($3/1024)}'`
      sub_h=`echo ${result_sub}|awk -F';' '{print $4}'`
      if [[ "${vc_c}" -eq "${sub_c}" && "${vc_r}" -eq "${sub_r}" && "${vc_h}" -eq "${sub_h}" ]]; then
         echo "Server ${line};we have equal subscription" >> ${F_OKSUB}
      elif [[ "${vc_c}" -eq "${sub_c}" && "${vc_r}" -eq "${sub_r}" ]]; then
         echo "Server ${line};HDD_VC=${vc_h};HDD_SUB=${sub_h};NOT EQUAL" >> ${F_ERRH}
      elif [[ "${vc_c}" -eq "${sub_c}" && "${vc_h}" -eq "${sub_h}" ]]; then
         echo "Server ${line};RAM_VC=${vc_r};RAM_SUB=${sub_r};NOT EQUAL" >> ${F_ERRR}
      elif [[ "${vc_r}" -eq "${sub_r}" && "${vc_h}" -eq "${sub_h}" ]]; then
         echo "Server ${line};CPU_VC=${vc_c};CPU_SUB=${sub_c};NOT EQUAL" >> ${F_ERRC}
      elif [[ "${vc_c}" -ne "${sub_c}" && "${vc_r}" -ne "${sub_r}" ]]; then
         echo "Server ${line};CPU_VC=${vc_c};CPU_SUB=${sub_c};RAM_VC=${vc_r};RAM_SUB=${sub_r}" >> ${F_ERR}
      elif [[ "${vc_c}" -ne "${sub_c}" && "${vc_h}" -ne "${sub_h}" ]]; then
         echo "Server ${line};CPU_VC=${vc_c};CPU_SUB=${sub_c};HDD_VC=${vc_h};HDD_SUB=${sub_h}" >> ${F_ERR}
      elif [[ "${vc_c}" -ne "${sub_c}" && "${vc_r}" -ne "${sub_r}" ]]; then
         echo "Server ${line};CPU_VC=${vc_c};CPU_SUB=${sub_c};RAM_VC=${vc_r};RAM_SUB=${sub_r}" >> ${F_ERR}
      elif [[ "${vc_h}" -ne "${sub_h}" && "${vc_r}" -ne "${sub_r}" ]]; then
         echo "Server ${line};HDD_VC=${vc_h};HDD_SUB=${sub_h};RAM_VC=${vc_r};RAM_SUB=${sub_r}" >> ${F_ERR}
      else
         echo "Server ${line};ZHOPA" 
      fi
   fi
done <${TMPFILE1}

#Finishing our scripts
rm -f ${TMPFILE1}

if [[ ! -d ${D_BASE} ]]; then
   mkdir -p ${D_BASE}
fi
for F in ${F_2SUB} ${F_1SUB} ${F_NOSUB} ${F_OKSUB} ${F_ERRH} ${F_ERRR} ${F_ERRC} ${F_ERR}; do
   cp -f ${F} ${D_BASE}/
done

exit 0
