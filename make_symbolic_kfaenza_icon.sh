#!/bin/bash

infile="$1"
outfile="$2"
out_width="$3" #output_size

#--------------------------------------------------------------------------------

tmpdir=$(mktemp -d)

in_density=6000		#svg internal density resolution (6000=1000px)
in_resolution=1000  #px internal resolution (make it to match in_density)

dilate=30			#fatness 
					#16px-64px: 60 
					#>64px: 30

posterize=256		#reduce shades while embossing
					#16 to 64: 3
					#>64: 256
					
shadow=50x12+0+8	#final shadow 
					#16px: 100x48+0+0
					#32px::100x24+0+4
					#64px_out:100x18+0+6
					#else:50x12+0+8

unsharp=0x00		#additional sharpening to the final image 
					#16px:0x0.5 
					#32 to 64: 0x0.38
					#else:0x0
					
blur_emboss=0x24	#size of the emboss (0x12 to 0x36)



if (( $out_width <= 16 )) ; then
		dilate=45
		posterize=3
		shadow=450x9+0+2
		unsharp=0x0.2
	elif (( $out_width <= 24 )) ; then
		dilate=60
		posterize=3
		shadow=450x9+0+3
		unsharp=0x0.2
	elif (( $out_width <= 32 )) ; then
		dilate=60
		posterize=3
		shadow=100x24+0+4
		unsharp=0x0.38
	elif (( $out_width <= 64 )) ; then
		dilate=60
		posterize=3
		shadow=100x18+0+6
		unsharp=0x0.38
fi

echo "$dilate" "$posterize" "$shadow" "$unsharp"

# set default values
function color2alpha {
	pinfile="$1"
	poutfile="$2"
	color="$3"
	convert "$pinfile" -alpha off $tmpdir/tmp1.mpc
	convert $tmpdir/tmp1.mpc \
		\( -clone 0 -fill "$color" -colorize 100 \) \
		-compose difference -composite \
		-separate -evaluate-sequence max \
		-auto-level -evaluate pow 1 \
		$tmpdir/tmp2.mpc
	convert $tmpdir/tmp1.mpc $tmpdir/tmp2.mpc -alpha off -compose copy_opacity -composite "$poutfile"
	rm $tmpdir/tmp2.mpc $tmpdir/tmp1.mpc
}


#raster dell'svg:
#convert -background white -density $in_density -resize $in_resolution -contrast -contrast -contrast  -contrast -contrast -contrast  $infile PNG8:$tmpdir/wb.png
convert -background white -density $in_density -resize $in_resolution -contrast -contrast -contrast  -contrast -contrast -contrast -fill "#000000" -opaque "#101010" -fuzz 20% -fill "#ffffff" -opaque "#eeeeee" -fuzz 20%  $infile PNG8:$tmpdir/wb.png
#falla ciotta
convert  $tmpdir/wb.png -negate -morphology Dilate rectangle:$dilate  PNG8:$tmpdir/bw.png 
#buca il nero
convert  $tmpdir/bw.png   -transparent black -fuzz 0% -negate PNG32:$tmpdir/bwa.png
#color2alpha $tmpdir/bw.png $tmpdir/bwa1.png black
#convert $tmpdir/bwa1.png -negate $tmpdir/bwa.png

#emboss
convert  $tmpdir/bwa.png  -alpha deactivate  -blur $blur_emboss  -shade 90x45 -alpha activate -normalize -level 100% -normalize -posterize $posterize PNG8:$tmpdir/emboss.png
#fai un trim temporaneo per capire quanto dovrà essere alto il gradiente e scrivi le info in 2 file
convert $tmpdir/bw.png -trim -format '%h' -write info:$tmpdir/h.png.txt -format '%w' -write info:$tmpdir/w.png.txt $tmpdir/delme.png
#assegna a due variabili
w=$(cat $tmpdir/w.png.txt) ; h=$(cat $tmpdir/h.png.txt)
#crea un gradiente della grandezza dell'immagine trimmata, non so perchè, ma gli devo dare un 20% in più all'altezza
convert -size "$w"x"$h" gradient:#dbdbdb-#606060 -resize 200%x120% $tmpdir/gradient.png
#disegna il gradiente sull'immagine, al centro.
convert -gravity center -compose screen -composite  $tmpdir/emboss.png $tmpdir/gradient.png  $tmpdir/emboss.png $tmpdir/emboss_gradient.png

convert $tmpdir/emboss_gradient.png \( +clone  -background black  -shadow $shadow  \) +swap  -background none  -layers merge +repage $tmpdir/shadowed.png

if (( $w > $h )) ; then 
	resizeoption=$out_width
		else
	resizeoption=x"$out_width"
fi

#ricava una maschera di colore per ripristinare le informazioni cromatiche
	#convert -background white -density $in_density  -fill "#000000" -opaque "#101010" -fuzz 20%     -resize $in_resolution $infile PNG8:$tmpdir/c1.png
	#convert  $tmpdir/c1.png -negate -morphology Dilate rectangle:$dilate PNG8:$tmpdir/c2.png
	#convert $tmpdir/c2.png -negate -transparent white  $tmpdir/colors.png

	#convert $tmpdir/bw.png -negate -transparent white  -modulate 100,300,100 $tmpdir/colors.png

	convert -density $(( $in_density*2 )) $infile -filter point -resize $(( $in_resolution/4 )) -morphology Erode rectangle:$(( $dilate/4 )) -fuzz 20% -transparent white -fuzz 20% -transparent black  -alpha on -channel A -fx "saturation<0.05?0:1"  -resize $in_resolution  -modulate 100,100,100 $tmpdir/colors.png
	
	
#Componi e ripristina il colore (e aumenta la saturazione via modulate)

convert $tmpdir/shadowed.png  $tmpdir/colors.png -gravity center -compose darken -composite  png32:$tmpdir/shadowed_colored.png


convert -trim $tmpdir/shadowed_colored.png -resize $resizeoption  -background none -gravity center -unsharp $unsharp -extent "$out_width"x"$out_width"  PNG32:"$outfile"

#rm -R $tmpdir

