#! /usr/bin/env bash

set -e

# Unconditionally download 3.7.0 along and ignor requested GemStone version.
#
gemstoneversion="$1"
if [ "$gemstoneversion"x = "x" ]; then
	gemstoneversion="3.7.1"
else
	case "$gemstoneversion" in
		3.7.0|3.7.1)
			# we're good
			;;
		*)
			echo "only gemstone version 3.7.0, 3.7.1 or 3.7.2 should be used"
			exit 1
	esac
fi
PLATFORM="`uname -sm | tr ' ' '-'`"
case "$PLATFORM" in
   Linux-aarch64)
		dlname="GemStone64Bit${gemstoneversion}-arm64.Linux"
		format=zip
		;;
   Darwin-arm64 )
		dlname="GemStone64Bit${gemstoneversion}-arm64.Darwin"
		format=dmg
		;;
   Darwin-x86_64)
		dlname="GemStone64Bit${gemstoneversion}-i386.Darwin"
		format=dmg
		;;
	Linux-x86_64)
		dlname="GemStone64Bit${gemstoneversion}-x86_64.Linux"
		format=zip
     ;;
	*)
		echo "This script should only be run on Mac (Darwin-i386 or Darwin-arm64), or Linux (Linux-x86_64) ). The result from \"uname -sm\" is \"`uname -sm`\""
		exit 1
     ;;
esac

superDoit="`dirname $0`/.."
products=$superDoit/gemstone/products
cd $products

if [ ! -d "${dlname}" ]; then
	needsDownload="true"
	if [ $# -eq 1 ]; then
		commonProducts="$1"
		if [ -d "${commonProducts}/${dlname}" ] ; then
			echo "Making symbolic link in `pwd` to ${commonProducts}/${dlname} for $PLATFORM"
			ln -s "${commonProducts}/${dlname}" .
			needsDownload="false"
		fi
	fi
	if [ "$needsDownload" = "true" ] ; then
		echo "Downloading ${dlname} to `pwd` for $PLATFORM"
		curl  -L -O -S "https://downloads.gemtalksystems.com/pub/GemStone64/${gemstoneversion}/${dlname}.${format}"
		case "$format" in
			zip)
				unzip ${dlname}.zip
				;;
			dmg)
				VOLUME=`hdiutil attach ${dlname}.dmg | grep Volumes | awk '{print $3}'`
				cp -rf ${VOLUME}/${dlname} .
				hdiutil detach $VOLUME
				;;
		esac
	fi
	
	cd ../solo
	echo "Making symbolic link in `pwd` for $dlname" 
	ln -s ../products/${dlname} product
	
	echo "Copying extent0.rowan.dbf and extent0.solo.dbf"
	cp ../products/${dlname}/bin/extent0.rowan.dbf extent0.solo.dbf
	chmod -w extent0.solo.dbf
	echo "Copying extent0.dbf to extent0.dbf"
	cp ../products/${dlname}/bin/extent0.dbf extent0.dbf
	chmod -w extent0.dbf
	if [ "$gemstoneversion" = "3.7.1" ]; then
		echo "Copying extent0.rowan3.dbf"
		cp ../products/${dlname}/bin/extent0.rowan3.dbf .
		chmod -w extent0.rowan3.dbf
	fi
else
	echo "${dlname} has already been installed in `pwd` for $PLATFORM"
fi
