#!/bin/bash

infile="$1"
outfile="$2"
out_width="$3" #output_size

#--------------------------------------------------------------------------------

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



if (( $out_width <= 22 )) ; then
		dilate=60
		posterize=3
		shadow=100x48+0+0
		unsharp=0x0.5 
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
	convert "$pinfile" -alpha off /tmp/tmp1.mpc
	convert /tmp/tmp1.mpc \
		\( -clone 0 -fill "$color" -colorize 100 \) \
		-compose difference -composite \
		-separate -evaluate-sequence max \
		-auto-level -evaluate pow 1 \
		/tmp/tmp2.mpc
	convert /tmp/tmp1.mpc /tmp/tmp2.mpc -alpha off -compose copy_opacity -composite "$poutfile"
	rm /tmp/tmp2.mpc /tmp/tmp1.mpc
}


rm /tmp/*.png
rm /tmp/*.png.txt

#raster dell'svg:
convert -background white -density $in_density -resize $in_resolution -contrast -contrast -contrast  -contrast -contrast -contrast  $infile PNG8:/tmp/wb.png
#falla ciotta
convert  /tmp/wb.png -negate -morphology Dilate rectangle:$dilate PNG8:/tmp/bw.png 
#buca il nero
convert  /tmp/bw.png   -transparent black -fuzz 0% -negate PNG32:/tmp/bwa.png
#color2alpha /tmp/bw.png /tmp/bwa1.png black
#convert /tmp/bwa1.png -negate /tmp/bwa.png

#emboss
convert  /tmp/bwa.png  -alpha deactivate  -blur $blur_emboss  -shade 90x45 -alpha activate -normalize -level 100% -normalize -posterize $posterize PNG8:/tmp/emboss.png
#fai un trim temporaneo per capire quanto dovrà essere alto il gradiente e scrivi le info in 2 file
convert /tmp/bw.png -trim -format '%h' -write info:/tmp/h.png.txt -format '%w' -write info:/tmp/w.png.txt /tmp/delme.png
#assegna a due variabili
w=$(cat /tmp/w.png.txt) ; h=$(cat /tmp/h.png.txt)
#crea un gradiente della grandezza dell'immagine trimmata, non so perchè, ma gli devo dare un 20% in più all'altezza
convert -size "$w"x"$h" gradient:#dbdbdb-#606060 -resize 200%x120% /tmp/gradient.png
#disegna il gradiente sull'immagine, al centro.
convert -gravity center -compose screen -composite  /tmp/emboss.png /tmp/gradient.png  /tmp/emboss.png /tmp/emboss_gradient.png

convert /tmp/emboss_gradient.png \( +clone  -background black  -shadow $shadow \) +swap  -background none  -layers merge +repage /tmp/shadowed.png


convert -trim /tmp/shadowed.png -resize $out_width  -background none -gravity center -unsharp $unsharp -extent "$out_width"x"$out_width"  PNG32:"$outfile"


