#!/bin/bash 

#	per ogni file di breeze in actions/*
#		in kfaenza-koko, fai un link ln -s sourcebysize/nome actions/nome

SCRIPTDIR=${0%/*} 
cd $SCRIPTDIR/actions || exit

size=$1
cd $size
for file in /usr/share/icons/breeze/actions/$size/* ; do 
	icon=$(basename $file|rev|cut -c 5-|rev)
	src_icon=../../source-by-size/$size/$icon.png
	dst_icon=./$icon.png
	if [ ! -e $dst_icon ] ; then
		if [ -e $src_icon ] ; then
			echo ln -s $src_icon $dst_icon
			ln -s $src_icon $dst_icon
		fi
	fi
done
