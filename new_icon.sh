#!/bin/bash
#speedometer.png
#kt-speed-limits.png

script=/koko/.local/share/icons/kfaenza-koko/make_symbolic_kfaenza_icon.sh
name=document-send



for s in 16 22 24 32 48 64 96 128 256 ; do 
	for dilate in 10 20 30 40 50 60 ; do 
		dest=/koko/.local/share/icons/kfaenza-koko/working/$name/$s/$dilate
		mkdir -p $dest/lightsup &>/dev/null
		$script /usr/share/icons/breeze/actions/22/$name.svg \
			$dest/$name.png \
			$s $dilate
			convert $dest/$name.png -level 0%,95% $dest/lightsup/$name.png
	done
done
