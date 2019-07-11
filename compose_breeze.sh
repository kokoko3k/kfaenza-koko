#!/bin/bash

echo "under over size opacity(0..1) \#overcolor(or \"transparent\") dest"


under=$1
over=$2
size=$3
opacity=$4 #0..1
fill=$5 #or "transparent" to disable tinting
dest=$6

tmp_over1=/tmp/tinted.png
tmp_over2=/tmp/alphed.png


if [ $fill == "transparent" ] ; then 
	convert -density 1000 -background none $over -resize $size   $tmp_over1
		else
	convert -density 1000 -background none $over -fuzz 50% -fill "$fill" -opaque black -resize $size   $tmp_over1
fi
convert $tmp_over1 -alpha on -channel a -evaluate multiply $opacity +channel png32:$tmp_over2
convert $under -background none $tmp_over2 -compose over -composite $dest

rm $tmp_over1  $tmp_over2
