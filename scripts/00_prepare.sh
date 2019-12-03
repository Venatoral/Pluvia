#!/bin/bash -e
# FIXME should check prereqs, OS, etc

get_key() {
	cat "$1" | grep -A1 "<key>$2</key>" | tail -1 | cut -d '>' -f 2 | cut -d '<' -f 1
}

mkdir -p work
cd work
unzip -p "$1" Restore.plist 2>/dev/null > Restore.plist
if [ ! -s Restore.plist ] ; then
	echo "Not an IPSW file: $1"
	rm -f Restore.plist
	exit 1
fi
ptype=`get_key Restore.plist ProductType`
pvers=`get_key Restore.plist ProductVersion`
build=`get_key Restore.plist ProductBuildVersion`
bcfg=`get_key Restore.plist BoardConfig`
rramdisk=`cat Restore.plist | grep -A999 '>RestoreRamDisks<' | grep -B999 -m1 '</dict>' | grep -A1 '>User<' | grep -F '.dmg<' | cut -d '>' -f 2 | cut -d '<' -f1`
sysimg=`cat Restore.plist | grep -A999 '>SystemRestoreImages<' | grep -B999 -m1 '</dict>' | grep -A1 '>User<' | grep -F '.dmg<' | cut -d '>' -f 2 | cut -d '<' -f1`
if [ "x$ptype" != "xiPhone3,1" ] ; then
	echo "Only the iPhone3,1 is currently supported."
	rm -f Restore.plist
	exit 1
fi
bndl=../FirmwareBundles/Down_${ptype}_${pvers}_${build}.bundle
if [ ! -d "$bndl" ]; then
	echo "Please use the iPhone3,1 iOS 6.1.3 IPSW as input."
	rm -f Restore.plist
	exit 1
fi
if [ "x$2" != "xreset" ]; then
if [ ! -f keys_${ptype}_${build}.txt ] ; then
echo "Getting iBoot keys for ${ptype} iOS $pvers ($build)"
page_name=`curl -sL "https://www.theiphonewiki.com/wiki/Category:IPhone_4_(${ptype})_Key_Page" | grep "_${build}_(${ptype})" | cut -d '"' -f 2`
if [ "x$page_name" = x ] ; then
	echo "Can't find key page for ${ptype} iOS ${pvers} ($build) on iPhone Wiki"
	rm -f Restore.plist
	exit 1
fi
keypg="https://www.theiphonewiki.com$page_name"
curl -sL "$keypg" | grep keypage-iboot- | cut -d '"' -f 2-3 > keys_${ptype}_${build}.txt
else
echo "Using cached iBoot keys for ${ptype} iOS $pvers ($build)"
fi
key=`cat keys_${ptype}_${build}.txt | grep iboot-key | cut -d '>' -f 2 | cut -d '<' -f 1`
if [ "x$key" = x ] ; then
	echo "Can't find iBoot key for ${ptype} iOS ${pvers} ($build)"
	rm -f Restore.plist keys_${ptype}_${build}.txt
	exit 1
fi
iv=`cat keys_${ptype}_${build}.txt | grep iboot-iv | cut -d '>' -f 2 | cut -d '<' -f 1`
if [ "x$iv" = x ] ; then
	echo "Can't find iBoot IV for ${ptype} iOS ${pvers} ($build)"
	rm -f Restore.plist keys_${ptype}_${build}.txt
	exit 1
fi
echo $iv > iv
echo $key > key
fi
echo $ptype > ptype
echo $pvers > pvers
echo $build > build
echo $bcfg > bcfg
echo $rramdisk > rramdisk
echo $sysimg > sysimg
rm -f Restore.plist
