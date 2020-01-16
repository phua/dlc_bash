#!/bin/sh

# Usage: ./dlc_decrypt.sh /path/to/file.dlc

if [ $# -lt 1 ]; then
    echo "Usage: \$ $0 /path/to/file.dlc"
    exit 1
fi

URL="http://service.jdownloader.org/dlcrypt/service.php?srcType=dlc&destType=pylo&data="
KEY="cb99b5cbc24db398"
IV="9bc24cb995cb8db3"

DLC_KEY=$(tail -c 88 "$1")
RC=$(curl -s "${URL}${DLC_KEY}" | sed -E 's/<rc>(.*)<\/rc>/\1/' | base64 -d -w 0)
DLC_KEY=$(echo -n "${RC}" | openssl enc -aes-128-cbc -d -a -nosalt -K "${KEY}" -iv "${IV}")

LEN=$(expr $(wc -c "$1" | awk '{ print $1 }') - 88)
head -c ${LEN} "$1" | base64 -d -w 0 | openssl enc -aes-128-cbc -nosalt -d -a -K ${DLC_KEY} -iv ${DLC_KEY} | base64 -d -w 0
