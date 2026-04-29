#!/usr/bin/env bash

# make-img.sh
# A simple script for creating an empty file system image


WRONG_FLAG=1
CANCELED=2
DD_ERROR=3
MKFS_ERROR=4

yN_prompt_wall() {
	case $1 in
		Y ) ;;
		* ) exit $CANCELED ;;
	esac
}

# We can add new flags if we want it
while [[ $# -gt 0 ]]; 
	do case "$1" in -h|--help)
			echo make-img.sh
			echo -e "\tusing:" make-img.sh [options]
			echo Create an IMG file with specified fily system
			echo OPTIONS:
			echo -e "\t-h|--help\tshow this message"
			echo -e "\t-u|--size-unit\tset unit size (see man dd for details)"
			echo -e "\t-s|--size\tset file size"
			echo -e "\t-f|--file-system\tset file system (see man mkfs for details)"
			echo -e "\t-p|--IMG-path\tset path to creating IMG"
			echo DEFAULTS:
			echo -e "\t--size-unit=M"
			echo -e "\t--size=512"
			echo -e "\t--file-system=ext4"
			echo -e "\t--img-path=./{file system}.img"
			echo
			echo -e NOTICE: it\'s just a funny script written when I
			echo know that I can create an IMG with simple dd command
			echo and mkfs
			echo Do not consider it as a "sirious" script "=)"
			exit 0
		;;
		-u|--size-unit)
			SIZE_UNIT=$2
			shift 2
		;;
		-s|--size)
			SIZE=$2
			shift 2
		;;
		-f|--file-system)
			FILE_SYSTEM=$2
			shift 2
		;;
		-p|--img-path)
			IMG_PATH=$2
			shift 2
		;;
		*)
			echo Unknown flag \"$1.\" 'Use make-img.sh --help|-h to see flags' >&2
			exit $WRONG_FLAG	
		;;
	esac
done

if [[ -z $SIZE_UNIT ]]; then
	SIZE_UNIT="M"
	echo Unit size is not specified. Using \"$SIZE_UNIT\" suffix '(kilobytes)' >&2
fi

if [[ -z $SIZE ]]; then
	SIZE="512"
	echo Block size is not specified. Using $SIZE >&2
fi

if [[ -z $FILE_SYSTEM ]]; then
	FILE_SYSTEM=ext4
	echo File system is not specified. Using \"$FILE_SYSTEM\" >&2
fi

if [[ -z $IMG_PATH ]]; then
	IMG_PATH=$(pwd)/"$FILE_SYSTEM.img"
	echo IMG file path is not specified. Using \"$IMG_PATH\" >&2
	
	echo Accept? '[y/N]'
	read resp
	yN_prompt_wall $resp
fi

# WE ALMOST DONE!

if [[ -f "$IMG_PATH" ]]; then
	echo "Found IMG with the same name"

	echo Delete it? '[y/N]'
	read resp
	yN_prompt_wall $resp

	rm -f "$IMG_PATH"
fi

echo Creating IMG file filled with zeroes...
dd if=/dev/zero of="$IMG_PATH" bs=$SIZE$SIZE_UNIT count=1 1>/dev/null 2>.dderr
ddcode=$?
if [[ $ddcode -ne 0 ]]; then
	echo Failed to create IMG file... dd exited with code $ddcode >&2
	err=$(cat .dderr)

	if [[ -n $err ]]; then
		echo "Error text:" 1>&2
	fi

	rm .dderr
	exit $DD_ERROR
fi
rm .dderr

echo Creating file system...
mkfs -t $FILE_SYSTEM "$IMG_PATH" 1>/dev/null 2>.mkfserr
mkfscode=$?
if [[ $mkfscode -ne 0 ]]; then
	echo Failed to create file system... mkfs exited with code $mkfscode >&2
	err=$(cat .mkfserr)
	
	if [[ -n $err ]]; then
		echo "Error text:" 1>&2
	fi

	rm .mkfserr
	exit $MKFS_ERROR
fi
rm .mkfserr

echo Done!
echo Now you can mount $IMG_PATH where you want using:
echo -e "\tsudo mount -o loop \"$IMG_PATH\" <mount path>"
echo Good luck!
