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

DIRECTORY="."
if [ $# -eq 2 ]; then
   DIRECTORY=$2
fi

# zippyshare LINK DIRECTORY
function zippyshare() {
    LINK=$1
    DIRECTORY=$2
    [[ "${LINK}" =~ ^#.* ]] && continue

    local IFS=","

    DOWNLOAD_LINK=($(curl -s ${LINK} | grep "'dlbutton'" | cut -d= -f2 | awk '{ split($0, s, "\""); print s[2] "," s[3] "," s[4] }'))
    DOWNLOAD_LINK[1]=${DOWNLOAD_LINK[1]#" + "}
    DOWNLOAD_LINK[1]=${DOWNLOAD_LINK[1]%" + "}
    DOWNLOAD_LINK[1]=$(echo ${DOWNLOAD_LINK[1]} | bc)
    DOWNLOAD_LINK=${LINK%/v*}${DOWNLOAD_LINK[0]}${DOWNLOAD_LINK[1]}${DOWNLOAD_LINK[2]}

    # echo \
        wget -P "${DIRECTORY}" ${DOWNLOAD_LINK}
}
export -f zippyshare

parallel -d, -j4 zippyshare ::: ${LINKS[@]} ::: ${DIRECTORY}
