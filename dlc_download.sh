#!/bin/sh

# Usage: $ ./dlc_download.sh /path/to/file.dlc [/path/to/download]

if [ $# -lt 1 ]; then
    echo "Usage: \$ $0 /path/to/file.dlc [/path/to/download]"
    exit 1
fi

SAVE_IFS=$IFS
IFS=","

DCRYPT_IT="http://dcrypt.it/decrypt/upload"

LINKS=
case "${1##*.}" in
    dlc)
        LINKS=($(curl -s -F "dlcfile=@$1" ${DCRYPT_IT} | sed -n '2p' | jq --raw-output '.[] | .links | join(",")'))
        ;;
    txt)
        LINKS=($(paste -sd "," $1))
        ;;
    csv)
        LINKS=($(<$1))
        ;;
    *)
        echo "Invalid input file: $1"
        exit 1
        ;;
esac

printf "Downloading %s files.\n" ${#LINKS[@]}
# printf "%s\n" ${LINKS[@]}
# for i in "${!LINKS[@]}"; do
#     printf "%s\t%s\n" $i ${LINKS[$i]}
# done

DIRECTORY="."
if [ $# -eq 2 ]; then
   DIRECTORY=$2
fi

function zippyshare() {
    LINK=$1
    DIRECTORY=$2
    [[ "${LINK}" =~ ^#.* ]] && continue

    local IFS=","

    DOWNLOAD_LINK=$(curl -s ${LINK} | grep "'dlbutton'")
    TEMP=""
    if [[ ${DOWNLOAD_LINK} == *"(a * b + c + d)"* ]]; then
        TEMP=$(mktemp)
        curl -s ${LINK} | grep -A 9 '^<script type="text/javascript">$' | \
            tail -n 9 | \
            sed -e "s/document.getElementById('dlbutton').href/var e/" > ${TEMP}
        echo "print(e)" >> ${TEMP}
        E=$(jjs ${TEMP})
        DOWNLOAD_LINK=${LINK%/v/*}${E}
    elif [[ ${DOWNLOAD_LINK} == *"(n + n * 2 + b)"* ]]; then
        TEMP=$(mktemp)
        curl -s ${LINK} | grep -A 3 '^<script type="text/javascript">$' | \
            tail -n 3 | \
            sed -e "s/document.getElementById('dlbutton').href/var e/" > ${TEMP}
        echo "print(e)" >> ${TEMP}
        E=$(jjs ${TEMP})
        DOWNLOAD_LINK=${LINK%/v/*}${E}
    elif [[ ${DOWNLOAD_LINK} == *"(Math.pow(a, 3)+b)"* ]]; then
        TEMP=$(mktemp)
        curl -s ${LINK} | grep -A 4 '^<script type="text/javascript">$' | \
            tail -n 4 | \
            sed -e "s/document.getElementById('dlbutton').omg =/var c =/" | \
            sed -e "s/document.getElementById('dlbutton').omg.length/c.length/" |\
            sed -e "s/document.getElementById('dlbutton').href/var e/" > ${TEMP}
        echo "print(e)" >> ${TEMP}
        E=$(jjs ${TEMP})
        DOWNLOAD_LINK=${LINK%/v/*}${E}
    else
        DOWNLOAD_LINK=($(curl -s ${LINK} | grep "'dlbutton'" | cut -d= -f2 | awk '{ split($0, s, "\""); print s[2] "," s[3] "," s[4] }'))
        DOWNLOAD_LINK[1]=${DOWNLOAD_LINK[1]#" + "}
        DOWNLOAD_LINK[1]=${DOWNLOAD_LINK[1]%" + "}
        DOWNLOAD_LINK[1]=$(echo ${DOWNLOAD_LINK[1]} | bc)
        DOWNLOAD_LINK=${LINK%/v/*}${DOWNLOAD_LINK[0]}${DOWNLOAD_LINK[1]}${DOWNLOAD_LINK[2]}
    fi

    echo "Downloading ${DOWNLOAD_LINK} ..."
    wget -q -c -P "${DIRECTORY}" ${DOWNLOAD_LINK}
         # --referer=$URL \
         # --cookies=off --header "Cookie: JSESSIONID=<session_id>" \
         # --user-agent='Mozilla/5.0 (Windows NT 6.0) Gecko/20100101 Firefox/14.0.1'

    if [[ ${TEMP} != "" ]]; then
        rm ${TEMP}
    fi
}
export -f zippyshare

# # while IFS= read -r URL; do
# for LINK in "${LINKS[@]}"; do
#     zippyshare ${LINK} ${DIRECTORY}
# done # < $1

# mkfifo LNK

parallel -d, -j8 zippyshare ::: ${LINKS[@]} ::: ${DIRECTORY}
