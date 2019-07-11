#!/bin/bash

echo "source tint saturation_percent method(overlay,colorize)"


source=$1
tint=$2
saturation=$3 #0..1 #equivalent to gimpìs layer transparency
method=$4  #overlay,colorize
dest=$1.tint.png

tmpdir=/tmp/colorizing
mkdir $tmpdir &>/dev/null

#Trova dimensioni immagine
convert $source -format '%h' -write info:$tmpdir/h.txt -format '%w' -write info:$tmpdir/w.txt /dev/null
#assegna a due variabili
w=$(cat $tmpdir/w.txt) ; h=$(cat $tmpdir/h.txt)

#crea rettangolo di colore
convert -size "$w"x"$h" xc:"$tint" -modulate 100,$saturation  png32:$tmpdir/rect.png

#rende grigia l'icona
convert $source -modulate 100,0  png32:$tmpdir/sourcebw.png

#colora l'icona
convert $tmpdir/sourcebw.png $tmpdir/rect.png -compose $method -composite $tmpdir/colorized.png

#ripristina canale alpha
convert $tmpdir/colorized.png $source -compose copyalpha -composite $dest

#convert $source -fill "$tint" -tint 100% -modulate 100,40 $dest

#dolphin $tmpdir
#rm $tmpdir
