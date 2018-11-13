#!/bin/bash

TMPF1=$(mktemp)
FDEVTMP=$(mktemp)
FDEVTEAM=/etc/sysconfig/network-scripts/ifcfg-team0
FDEVBOND=/etc/sysconfig/network-scripts/ifcfg-team0

ip a | grep -B 1 'link/ether' | grep -e '^[1-9]' | awk -F':' '{print $2}' >> ${FDEVTMP}

cr_tm_ports() {
count=1
while read line; do
    nmcli con add type team-slave con-name port${count} ifname ${line} master team0
    nmcli con del ${line} > /dev/null 2>&1
    count=$(( count+=1 ))
done < ${FDEVTMP}
}

cr_bd_ports() {
count=1
while read line; do
    nmcli con add type team-slave con-name port${count} ifname ${line} master team0
    nmcli con del ${line} > /dev/null 2>&1
    count=$(( count+=1 ))
done < ${FDEVTMP}
}

read -p "Select Bonding(B) or Beaming(T): " TYP
read -p "Select mode Active-Backup(AB) or LACP(LA): " MOD
read -p "Set ip addres with mask prefix: " IPADDR
read -p "Set gw addres: " GWADDR

if [ -e ${FDEVTEAM}]; then exit 0; fi
if [ -e ${FDEVBOND}]; then exit 0; fi

if [[ ${TYP} -eq "B" ]]; then
  if [[ ${MOD} -eq "AB" ]]; then
    echo "Bonding in Active-Backup mode is deprecated, we are going to build Team Active-Backup"
    nmcli con add type team con-name team0 ifname team0 ip4 ${IPADDDR} GW4 ${GWADDR} ipv4.dns '10.128.132.84 10.132.138.121 10.164.134.69' ipv4.method manual ipv6.method ignore
    echo "TEAM_CONFIG='{\"funner\":{\"name\":\"activebackup\"},\"link_watch\":{\"name\":\"ethtool\"}}'" >> ${FDEVTEAM}
    cr_tm_ports
  elif [[ ${MOD} -eq "LA" ]]; then
    nmcli con add type bond con-name bond0 ifname bond0 ip4 ${IPADDR} GW4 ${GWADDR} ipv4.dns '10.128.132.84 10.132.138.121 10.164.134.69' ipv4.method manuall ipv6.method ignore
    echo "BOND_OPTS=\"miimon=100 mode=802.3ad lacp_rate=1\"" >> ${FDEVBOND}
    cr_bd_ports
  else
     echo "It seems you do not understand what you are going to do. I'm thinking about it"
     exit 0
  fi
elif [[ ${TYP} -eq "T" ]]; then
  if [[ ${MOD} -eq "AB" ]]; then
    nmcli con add type team con-name team0 ifname team0 ip4 ${IPADDDR} GW4 ${GWADDR} ipv4.dns '10.128.132.84 10.132.138.121 10.164.134.69' ipv4.method manual ipv6.method ignore
    echo "TEAM_CONFIG='{\"funner\":{\"name\":\"activebackup\"},\"link_watch\":{\"name\":\"ethtool\"}}'" >> ${FDEVTEAM}
    cr_tm_ports
  elif [[ ${MOD} -eq "LA" ]]; then
    nmcli con add type team con-name team0 ifname team0 ip4 ${IPADDDR} GW4 ${GWADDR} ipv4.dns '10.128.132.84 10.132.138.121 10.164.134.69' ipv4.method manual ipv6.method ignore
    echo "TEAM_CONFIG='{\"funner\":{\"name\":\"lacp\",\"active\":true,\"fast_rate\":true,\"tx_hash\":[\"eth\",\"ipv4\",\"ipv6\"]},\"link_watch\":{\"name\":\"ethtool\"},\"ports\":{\"port1\":{},\"port2\":{}}}'" >> ${FDEVTEAM}
    cr_tm_ports
  else
     echo "It seems you do not understand what you are going to do. I'm thinking about it"
     exit 0
  fi
else
  echo "It seems you do not understand what you are going to do. I'm thinking about it"
  exit 0
fi

rm -f ${TMPF1}

systemctl restart network

exit 0