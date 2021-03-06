#!/bin/bash
#
#####################################################
#                                                   #
# Author : Khavish Anshudass Bhundoo                #
# License : MIT                                     #
# Performs compression tests using multiple encoders#
#####################################################

#Check if a command line tool is installed on the server
function exists()
{
  command -v "$1" >/dev/null 2>&1
}

function usage()
{
  echo "Usage: $(basename "${BASH_SOURCE}") [options] image1.png image2.png ..."
  echo "Main Options"
  echo "--only-pik              	Redo the test[image generation + csv ] only for pik & regenerate plots"
  echo "--only-libjpeg          	Redo the test[image generation + csv ] only for libjpeg & regenerate plots"
  echo "--only-libjpeg-2000     	Redo the test[image generation + csv ] only for libjpeg 2000 & regenerate plots"
  echo "--only-guetzli          	Redo the test[image generation + csv ] only for guezli & regenerate plots"
  echo "--only-flif-lossy       	Redo the test[image generation + csv ] only for flif(lossy) & regenerate plots"
  echo "--only-webp             	Redo the test[image generation + csv ] only for webp(near-lossless) & regenerate plots"
  echo "--only-webp-lossy       	Redo the test[image generation + csv ] only for webp(lossy) and regenerate plots"
  echo "--only-bpg-lossy        	Redo the test[image generation + csv ] only for bgp(lossy) and regenerate plots"
  echo "--only-bpg-lossy-jctvc  	Redo the test[image generation + csv ] only for bgp(lossy) with jctvc and regenerate plots"
  echo "--only-mozjpeg          	Redo the test[image generation + csv ] only for mozjpeg and regenerate plots"
  echo "--only-av1              	Redo the test[image generation + csv ] only for av1 and regenerate plots"
  echo "--only-plots            	Only regenerate plots"
  echo "--only-csv              	Only regenerate csv files and plots"
  echo "--combine-plots         	Merge results of multiple images to create a single butteraugli and ssimulacra plot"
  echo "--heatmap_target_size=SIZE  Generate butteraugli heatmaps for a compressed image just above SIZE for each encoder"
  echo "--only-image-generation     Only generate compressed images + the csv files for various codecs and exit"
  #echo "--path=/path/goes/here 	Use all png images in directory as source(no trailing / )" #TODO
  #echo "--no-gnu-parallel          Do not use gnu-parallel  #TODO
  echo "--force-image-generation    Regenerate compressed images + the csv files even if csv files already exist(use with --combine-plots)"
  exit 1

}


function check_dependancies()
{

  missing_deps=false

  if ! exists butteraugli; then
    echo 'Butteraugli is not installed...exiting'
    missing_deps=true
  fi

  if ! exists guetzli; then
    echo 'Guetzli is not installed...exiting'
    missing_deps=true
  fi

  if ! exists ssimulacra; then
    echo 'Ssimulacra is not installed...exiting'
    missing_deps=true
  fi

  if ! exists identify; then
    echo 'ImageMagick is not installed...exiting'
    missing_deps=true
  fi

  if ! exists cpik || ! exists dpik ; then
    echo 'Pik is not installed...exiting'
    missing_deps=true
  fi

  if ! exists cwebp || ! exists dwebp ; then
    echo 'Webp is not installed...exiting'
    missing_deps=true
  fi

  if ! exists aomenc || ! exists dwebp ; then
    echo 'av1 is not installed...exiting'
    missing_deps=true
  fi

  if ! exists bc; then
    echo 'bc is not installed...exiting'
    missing_deps=true
  fi

  if ! exists jpeg; then
    echo 'libjpeg is not installed...exiting'
    missing_deps=true
  fi

  if ! exists opj_compress || ! exists opj_decompress ; then
    echo 'OpenJPEG is not installed...exiting'
    missing_deps=true
  fi

  if ! exists gnuplot; then
    echo 'gnuplot is not installed...exiting'
    missing_deps=true
  fi

  if ! exists zip; then
    echo 'zip is not installed...exiting'
    missing_deps=true
  fi

  if ! exists bpgenc || ! exists bpgdec ; then
    echo 'libbpg is not installed...exiting'
    missing_deps=true
  fi

  if ! exists flif; then
    echo 'flif is not installed...exiting'
    missing_deps=true
  fi

  if ! exists cjpeg || ! exists djpeg; then
    echo 'MozJPEG is not installed...exiting'
    missing_deps=true
  fi

  if ! exists datamash; then
    echo 'datamash is not installed...exiting'
    missing_deps=true
  fi

  if ! exists parallel; then
    echo 'gnu parallel is not installed...exiting'
    missing_deps=true
  fi

  if [ "$missing_deps" = true ] ; then
    exit 1
  fi


}

#Convert filesize(bytes) to bits per pixels(bpp)
function convert_to_bpp
{
  local filesize=$1
  local bpp
  local width=$2
  local height=$3
  bpp=$(echo "(($filesize * 8) / ($width * $height))" | bc -l)
  printf -v bpp "%0.2f" "$bpp" #set to 2 dp
  echo "$bpp"
}

function plotcsv_graph
{
  gnuplot -persist <<-EOFMarker
    	set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    	set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    	set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    	set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    	set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    	set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    	set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    	set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow
    	set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    	set tics nomirror
	set ytics 1
	set mytics 10
    	set output "$1"
	set title  "$3" noenhanced
    	set xlabel 'Bits per pixel(bpp)'
    	set ylabel 'butteraugli score'
	set style func linespoints
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	set arrow from $reference_jpg_bpp, graph 0 to $reference_jpg_bpp, graph 1 nohead lt 0
	plot "pik-$2.csv" using 3:4 w l ls 1 title 'pik', \
    	"libjpeg-$2.csv" using 3:4 w l ls 2  title 'libjpeg', \
	"libjpeg2000-$2.csv" using 3:4 w l ls 3  title 'OpenJPEG(JPEG 2000)', \
    	"guetzli-$2.csv" using 3:4 w l ls 4 title 'guetzli', \
    	"flif_lossy-$2.csv" using 3:4 w l ls 5 title 'flif-lossy', \
	"bpg-$2.csv" using 3:4 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-$2.csv" using 3:4 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-$2.csv" using 3:4 w l ls 8  title 'MozJPEG', \
	"av1-$2.csv" using 4:5 w l ls 9 title 'AV1', \
	"webp-$2.csv" using 3:4 w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-$2.csv" using 3:4 w l ls 12 title 'webp-lossy', \
	1/0 t "Reference Size" lt 0
EOFMarker
}

function plotcsv_graph_ssimulacra
{
  gnuplot -persist <<-EOFMarker
    set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    	set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    	set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    	set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    	set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    	set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    	set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    	set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow
    	set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    	set tics nomirror
	set ytics 0.01
	set mytics 10
    	set output "$1"
	set title  "$3" noenhanced
    	set xlabel 'Bits per pixel(bpp)'
    	set ylabel 'ssimulacra score'
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	set arrow from $reference_jpg_bpp, graph 0 to $reference_jpg_bpp, graph 1 nohead lt 0
	plot "pik-$2.csv" using 3:5 w l ls 1 title 'pik', \
    	"libjpeg-$2.csv" using 3:5 w l ls 2 title 'libjpeg', \
	"libjpeg2000-$2.csv" using 3:5 w l ls 3 title 'OpenJPEG(JPEG 2000)', \
    	"guetzli-$2.csv" using 3:5 w l ls 4 title 'guetzli', \
    	"flif_lossy-$2.csv" using 3:5 w l ls 5 title 'flif-lossy', \
	"bpg-$2.csv" using 3:5 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-$2.csv" using 3:5 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-$2.csv" using 3:5 w l ls 8 title 'MozJPEG', \
	"av1-$2.csv" using 4:6 w l ls 9 title 'AV1', \
	"webp-$2.csv" using 3:5 w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-$2.csv" using 3:5 w l ls 12 title 'webp-lossy', \
	1/0 t "Reference Size" lt 0
EOFMarker
}

function plotcsv_graph_merge
{
  gnuplot -persist <<-EOFMarker
	set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    	set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    	set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    	set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
   	set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    	set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    	set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    	set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow
    	set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    	set tics nomirror
	set ytics 1
	set mytics 10
    	set output "$1"
	set title  "$2" noenhanced
    	set xlabel 'Bits per pixel(bpp)'
    	set ylabel 'butteraugli score'
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	plot "pik-merge.csv" using 2:3 w l ls 1  title 'pik', \
    	"libjpeg-merge.csv" using 2:3 w l  ls 2 title 'libjpeg', \
	"libjpeg2000-merge.csv" using 2:3  w l ls 3 title 'OpenJPEG(JPEG 2000)', \
    	"guetzli-merge.csv" using 2:3 w l ls 4 title 'guetzli', \
    	"flif_lossy-merge.csv" using 2:3 w l ls 5 title 'flif-lossy', \
	"bpg-merge.csv" using 2:3 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-merge.csv" using 2:3 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-merge.csv" using 2:3 w l ls 8 title 'MozJPEG', \
	"av1-merge.csv" using 3:4 w l ls 9 title 'AV1', \
	"webp-merge.csv" using 2:3  w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-merge.csv" using 2:3 w l ls 12 title 'webp-lossy'
EOFMarker
}

function plotcsv_graph_ssimulacra_merge
{
  gnuplot -persist <<-EOFMarker
    	set terminal pngcairo size 1280,1024 enhanced font "Helvetica,20"
	set style line 1 lt 1 lw 2 lc rgb '#00707A' ps 0 # dark green
    	set style line 2 lt 1 lw 2 lc rgb '#8710A8' ps 0 # purple
    	set style line 3 lt 1 lw 2 lc rgb '#005ACB' ps 0 # dark blue
    	set style line 4 lt 1 lw 2 lc rgb '#099BFC' ps 0 # light blue
    	set style line 5 lt 1 lw 2 lc rgb '#FF75FE' ps 0 # pink
    	set style line 6 lt 1 lw 2 lc rgb '#08D8DD' ps 0 # cyan
    	set style line 7 lt 1 lw 2 lc rgb '#A90B3C' ps 0 # brown
    	set style line 8 lt 1 lw 2 lc rgb '#F67A4E' ps 0 # orange
	set style line 9 lt 1 lw 2 lc rgb '#09B460' ps 0 # dark green
	set style line 10 lt 1 lw 2 lc rgb '#EFEF3A' ps 0 # yellow
    	set style line 11 lt 1 lw 2 lc rgb '#A6F687' ps 0 # light green
	set style line 12 lt 1 lw 2 lc rgb '#FBE5BC' ps 0 # light brown
    	set tics nomirror
	set ytics 0.01
	set mytics 10
    	set output "$1"
	set title  "$2" noenhanced
    	set xlabel 'Bits per pixel(bpp)'
    	set ylabel 'ssimulacra score'
	set datafile separator ","
	set xtics font ", 12"
	set xrange [:8]
	plot "pik-merge.csv" using 2:4 w l ls 1 title 'pik', \
    	"libjpeg-merge.csv" using 2:4 w l ls 2 title 'libjpeg', \
	"libjpeg2000-merge.csv" using 2:4 w l ls 3 title 'OpenJPEG(JPEG 2000)', \
    	"guetzli-merge.csv" using 2:4 w l ls 4 title 'guetzli', \
    	"flif_lossy-merge.csv" using 2:4 w l ls 5 title 'flif-lossy', \
	"bpg-merge.csv" using 2:4 w l ls 6 title 'bpg(x265)', \
	"bpg_jctvc-merge.csv" using 2:4 w l ls 7 title 'bpg(jctvc)', \
	"mozjpeg-merge.csv" using 2:4 w l ls 8 title 'MozJPEG', \
	"av1-merge.csv" using 3:5 w l ls 9 title 'AV1', \
	"webp-merge.csv" using 2:4 w l ls 10 title 'webp-near-lossless-40/60', \
	"webp_lossy-merge.csv" using 2:4 w l ls 12 title 'webp-lossy'
EOFMarker
}
#######################################Handler functions START ###########################################################

function av1_generation_handler
{
  q="$1"
  i="$2"
  x="$3"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    aomenc "$x".y4m --i444 --enable-qm=1 --qm-min="$i" --profile=3 -w "$width" -h "$height" -b 10 --end-usage=q --cq-level="$q" -o "$x"_"$q"_"$i".ivf
    aomdec "$x"_"$q"_"$i".ivf --output-bit-depth=10 -o "$x"_"$q"_"$i".y4m
    ffmpeg -nostats -loglevel 0 -y -i "$x"_"$q"_"$i".y4m "$x"_"$q"_"$i".png
    convert "$x"_"$q"_"$i".png PNG24:"$x"_"$q"_"$i"_ssimulacra.png # ssimulacra can't handle generated png
  fi
  new_size=$(wc -c < "$filename"_"$q"_"$i".ivf)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_"$q"_"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_"$q"_"$i"_ssimulacra.png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$q","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> av1-"$filename".csv
}


function libjpeg_2000_generation_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    opj_compress -i "$x".ppm -r "$i" -o "$filename"_openjpeg_q"$i".jp2 -I -r "$i"
    opj_decompress -i "$filename"_openjpeg_q"$i".jp2  -o "$filename"_openjpeg_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_openjpeg_q"$i".jp2)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_openjpeg_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_openjpeg_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> libjpeg2000-"$filename".csv
}


function guetzli_generation_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    guetzli  --nomemlimit --quality "$i"  "$x"  "$filename"_guetzli_q"$i".jpg
  fi
  new_size=$(wc -c < "$filename"_guetzli_q"$i".jpg)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_guetzli_q"$i".jpg)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_guetzli_q"$i".jpg)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> guetzli-"$filename".csv
}


function mozjpeg_generation_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    cjpeg -optimize -sample 1x1 -quality "$i" -outfile "$filename"_mozjpeg_q"$i".jpg "$x"
  fi
  new_size=$(wc -c < "$filename"_mozjpeg_q"$i".jpg)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_mozjpeg_q"$i".jpg)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_mozjpeg_q"$i".jpg)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> mozjpeg-"$filename".csv
}

function pik_generation_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    cpik  "$x" "$filename"_q"$i".pik --distance "$i"
    dpik "$filename"_q"$i".pik "$filename"_pik_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_q"$i".pik)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_pik_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_pik_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> pik-"$filename".csv
}

function webp_near_lossless_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    cwebp -sharp_yuv -mt -quiet -near_lossless "$i" -q 100 -m 6 "$x"  -o "$filename"_webp_q"$i".webp
    dwebp -quiet "$filename"_webp_q"$i".webp -o "$filename"_webp_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_webp_q"$i".webp)
  new_size_bpp=$(convert_to_bpp "$new_size")
  butteraugli_score=$(butteraugli "$x" "$filename"_webp_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_webp_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> webp-"$filename".csv
}


function webp_lossy_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    cwebp -sharp_yuv -pass 10 -mt -quiet -q "$i" -m 6 "$x"  -o "$filename"_webp_lossy_q"$i".webp
    dwebp -quiet "$filename"_webp_lossy_q"$i".webp -o "$filename"_webp_lossy_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_webp_lossy_q"$i".webp)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_webp_lossy_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_webp_lossy_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> webp_lossy-"$filename".csv
}


function bpg_lossy_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    bpgenc -q "$i" -f 444  -m 9 "$x" -o "$filename"_bpg_q"$i".bpg
    #convert to png to allow comparision
    bpgdec "$filename"_bpg_q"$i".bpg -o "$filename"_bpg_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_bpg_q"$i".bpg)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_bpg_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_bpg_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> bpg-"$filename".csv
}



function bpg_lossy_jctvc_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    bpgenc -q "$i" -f 444  -m 9 -e jctvc "$x" -o "$filename"_bpg_jctvc_q"$i".bpg
    #convert to png to allow comparision
    bpgdec "$filename"_bpg_jctvc_q"$i".bpg -o "$filename"_bpg_jctvc_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_bpg_jctvc_q"$i".bpg)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_bpg_jctvc_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_bpg_jctvc_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> bpg_jctvc-"$filename".csv
}

function flif_lossy_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    flif -o -e -E100  -Q"$i"  "$x" "$filename"_lossy_q"$i".flif
    #convert to png to allow comparision
    flif  -o -d "$filename"_lossy_q"$i".flif "$filename"_flif_lossy_q"$i".png
  fi
  new_size=$(wc -c < "$filename"_lossy_q"$i".flif)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_flif_lossy_q"$i".png)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_flif_lossy_q"$i".png)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> flif_lossy-"$filename".csv
}

function libjpeg_generation_handler
{
  i="$1"
  x="$2"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  if [ "$only_csv" = false ]; then
    jpeg -q "$i" -oz -h -qt 3 -qv  "$x".ppm "$filename"_libjpeg_q"$i".jpg
  fi
  new_size=$(wc -c < "$filename"_libjpeg_q"$i".jpg)
  new_size_bpp=$(convert_to_bpp "$new_size" "$width" "$height")
  butteraugli_score=$(butteraugli "$x" "$filename"_libjpeg_q"$i".jpg)
  ssimulacra_score=$(ssimulacra "$x" "$filename"_libjpeg_q"$i".jpg)
  compression_rate=$(echo "(($orig_size - $new_size) / $orig_size) * 100" | bc -l)
  reference_compression_rate=$(echo "(($reference_jpg_size - $new_size) / $reference_jpg_size) * 100" | bc -l)
  printf -v compression_rate "%0.2f" "$compression_rate" #set to 2 dp
  printf -v reference_compression_rate "%0.2f" "$reference_compression_rate" #set to 2 dp
  echo "$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$compression_rate","$reference_compression_rate" >> libjpeg-"$filename".csv
}


#Export handler functions
export -f convert_to_bpp libjpeg_generation_handler av1_generation_handler libjpeg_2000_generation_handler guetzli_generation_handler mozjpeg_generation_handler pik_generation_handler webp_near_lossless_handler webp_lossy_handler bpg_lossy_handler bpg_lossy_jctvc_handler flif_lossy_handler


#################################Handler functions END ################################################################

#################################Test functions START ##################################################################

function libjpeg_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing JPEGs optimized by LibJPEG[Source :$x]"
  rm -rf libjpeg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size(bytes),Original_Size(bpp)" >> libjpeg-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> libjpeg-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> libjpeg-"$filename".csv
  parallel --will-cite  --load 100%  --delay 0.1 -k 'libjpeg_generation_handler {1} {2}' ::: {100..70} ::: "$x"
  { head -n3 libjpeg-"$filename".csv; tail -n +4 libjpeg-"$filename".csv | sort -k1,1 -r -n -t,; } >libjpeg-"$filename".tmp && mv libjpeg-"$filename".tmp libjpeg-"$filename".csv
#End csv generation
}



function av1_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing images optimized by AV1"
  rm -rf av1-"$filename".csv "$x".y4m
  ffmpeg -nostats -loglevel 0 -y -i  "$x" -pix_fmt yuv444p10le -strict -2 "$x".y4m
  #Start csv generation
  echo "Test_Image,Original_Size(bytes),Original_Size(bpp)" >> av1-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> av1-"$filename".csv
  echo "Quality(cq-level),Flatness(qm-min),Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> av1-"$filename".csv
  parallel --will-cite --load 100%  -k --delay 0.1 'av1_generation_handler {1} {2} {3}' ::: {10..40..2} ::: {4..12..2} ::: "$x"
  { head -n3 av1-"$filename".csv; tail -n +4 av1-"$filename".csv | sort -k1,1 -k2,2 -n  -t,; } >av1-"$filename".tmp && mv av1-"$filename".tmp av1-"$filename".csv
#End csv generation
}



function libjpeg_2000_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing JPEG 2000 images optimized by OpenJPEG(JPEG 2000)[Source :$x]"
  rm -rf libjpeg2000-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> libjpeg2000-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> libjpeg2000-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> libjpeg2000-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1  -k 'libjpeg_2000_generation_handler {1} {2}' ::: {0..25} ::: "$x"
  { head -n3 libjpeg2000-"$filename".csv; tail -n +4 libjpeg2000-"$filename".csv | sort -k1,1  -n -t,; } >libjpeg2000-"$filename".tmp && mv libjpeg2000-"$filename".tmp libjpeg2000-"$filename".csv
#End csv generation
}

function guetzli_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing JPEGs optimized by Guetzli[Source :$x]"
  rm -rf guetzli-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> guetzli-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> guetzli-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> guetzli-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1 -k  'guetzli_generation_handler {1} {2}' ::: {100..84} ::: "$x"
  { head -n3 guetzli-"$filename".csv; tail -n +4 guetzli-"$filename".csv | sort -k1,1 -r -n -t,; } >guetzli-"$filename".tmp && mv guetzli-"$filename".tmp guetzli-"$filename".csv
#End csv generation
}

function mozjpeg_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing JPEGs optimized by MozJPEG[Source :$x]"
  rm -rf mozjpeg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> mozjpeg-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> mozjpeg-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> mozjpeg-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1 -k  'mozjpeg_generation_handler {1} {2}' ::: {100..70} ::: "$x"
  { head -n3 mozjpeg-"$filename".csv; tail -n +4 mozjpeg-"$filename".csv | sort -k1,1 -r -n -t,; } >mozjpeg-"$filename".tmp && mv mozjpeg-"$filename".tmp mozjpeg-"$filename".csv
#End csv generation
}

function pik_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing Pik images(This will take a while...BE patient)[Source :$x]"
  rm -rf pik-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> pik-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> pik-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> pik-"$filename".csv
  parallel --will-cite --load 100%  --delay 0.1 -k  'pik_generation_handler {1} {2}' ::: $(seq 0.5 0.1 3.0) ::: "$x"
  { head -n3 pik-"$filename".csv; tail -n +4 pik-"$filename".csv | sort -k1,1  -n -t,; } >pik-"$filename".tmp && mv pik-"$filename".tmp pik-"$filename".csv
#End csv generation
}

function webp_near_lossless_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing Webp images(Near Lossless)[Source :$x]"
  rm -rf webp-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> webp-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> webp-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> webp-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1 -k 'webp_near_lossless_handler {1} {2}' ::: 60 40 ::: "$x"
  { head -n3 webp-"$filename".csv; tail -n +4 webp-"$filename".csv | sort -k1,1 -r -n -t,; } >webp-"$filename".tmp && mv webp-"$filename".tmp webp-"$filename".csv
#End csv generation
}

function webp_lossy_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing Webp images(Lossy)[Source :$x]"
  rm -rf webp_lossy-"$filename".csv
#Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> webp_lossy-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> webp_lossy-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> webp_lossy-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1  -k  'webp_lossy_handler {1} {2}' ::: {100..70} ::: "$x"
  { head -n3 webp_lossy-"$filename".csv; tail -n +4 webp_lossy-"$filename".csv | sort -k1,1 -r -n -t,; } >webp_lossy-"$filename".tmp && mv webp_lossy-"$filename".tmp webp_lossy-"$filename".csv
#End csv generation
}

function bpg_lossy_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing BPG images(x265 encoder - lossy)[Source :$x]"
  rm -rf bpg-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> bpg-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> bpg-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> bpg-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1 -k  'bpg_lossy_handler {1} {2}' ::: {0..37} ::: "$x"
  { head -n3 bpg-"$filename".csv; tail -n +4 bpg-"$filename".csv | sort -k1,1  -n -t,; } >bpg-"$filename".tmp && mv bpg-"$filename".tmp bpg-"$filename".csv
#End csv generation
}

function bpg_lossy_jctvc_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing BPG images(jctvc encoder - lossy)[Source :$x]"
  rm -rf bpg_jctvc-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> bpg_jctvc-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> bpg_jctvc-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> bpg_jctvc-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1 -k 'bpg_lossy_jctvc_handler {1} {2}' ::: {0..37} ::: "$x"
  { head -n3 bpg_jctvc-"$filename".csv; tail -n +4 bpg_jctvc-"$filename".csv | sort -k1,1 -n -t,; } >bpg_jctvc-"$filename".tmp && mv bpg_jctvc-"$filename".tmp bpg_jctvc-"$filename".csv
  #End csv generation
}

function flif_lossy_test
{
  x="$1"
  filename=$(basename "$x")
  width=$(identify -format "%w" "$x")
  height=$(identify -format "%h" "$x")
  orig_size=$(wc -c < "$x")
  orig_size_bpp=$(convert_to_bpp "$orig_size" "$width" "$height")
  echo "Analysing FLIF images(Lossy)[Source :$x]"
  rm -rf flif_lossy-"$filename".csv
  #Start csv generation
  echo "Test_Image,Original_Size,Original_Size(bpp)" >> flif_lossy-"$filename".csv
  echo "$filename","$orig_size","$orig_size_bpp" >> flif_lossy-"$filename".csv
  echo "Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,Compression Rate(%),Reference Compression Rate(%)" >> flif_lossy-"$filename".csv
  parallel --will-cite --load 100% --delay 0.1 -k  'flif_lossy_handler {1} {2}' ::: {100..0} ::: "$x"
  { head -n3 flif_lossy-"$filename".csv; tail -n +4 flif_lossy-"$filename".csv | sort -k1,1 -r -n -t,; } >flif_lossy-"$filename".tmp && mv flif_lossy-"$filename".tmp flif_lossy-"$filename".csv
  #End csv generation
}

#################################Test functions END ##################################################################

#Performs operations that are needed only once for all input images BEFORE image generation starts
function global_operations
{
  x="$1"
  filename=$(basename "$x")
#if original image is not sRGB , convert the colorspace to sRGB so that ssimulacra can work fine
  colorspace=$(identify -format "%[colorspace]" "$x")
  if [ "$colorspace" != "sRGB" ]; then
    convert "$x" -define png:color-type=2 "$x"
  fi
#
  if [ ! -e "$filename".ppm ] || [ ! -e  "$filename"_libjpeg_reference.jpg ]; then
    convert "$x" "$x".ppm # libjpeg will require ppm file as input
    jpeg -q 93 -oz -h -qt 3 -qv "$x".ppm "$filename"_libjpeg_reference.jpg &> /dev/null
  fi
}


#Generate individual plots in parallel
function generate_single_plots
{
  filename="$1"
  echo "Generating the plots[Source :$x]"
  rm -rf "$filename"_butteraugli_plot.png "$filename"_ssimulacra_plot.png
  reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
  reference_jpg_bpp=$(convert_to_bpp "$reference_jpg_size")
  plotcsv_graph "$filename"_butteraugli_plot.png "$filename"  "Source: $filename"
  plotcsv_graph_ssimulacra "$filename"_ssimulacra_plot.png  "$filename" "Source: $filename"
}

# As its nsmae suggest this is the function that get called first when the script is run
# The flow is as follows
# 1.Performs some basic validations
# 2.Process the flags
# 3.The image generation is as follows (for each image)
#	 - The main functions call the _test functions which are responsible for preparing the csv files
#    - The _test functions call the corresponding _handler functions which are responsible for doing the conversions
# 4.Generate butteraugli and ssimulacra single plots for each image
# 5.Generate merge plots if needed
# 6.Generate comparison csv for each image if needed
# 7.Generate the zip file
# 8.Exit
function main
{

  check_dependancies

  if [ "$#" -le 0 ]; then
    usage
  else
    for x in "$@"; do
      if [ "${x: 0:2}" != "--" ] && [ "${x: -4}" != ".png" ]; then
        echo "Only PNG images are supported"
        exit 1
      fi

      if [ "${x: 0:2}" != "--" ] && [ "${x: -4}" == ".png" ] &&  ! identify "$x" &> /dev/null; then
        echo  "$x doesn't seem to be a valid PNG...existing"
        exit 1
      fi
    done
  fi



#check which  flags are used
  has_options=false
  only_pik=false
  only_av1=false
  only_libjpeg=false
  only_libjpeg_2000=false
  only_guetzli=false
  only_webp=false
  only_webp_lossy=false
  only_bpg_lossy=false
  only_bpg_lossy_jctvc=false
  only_mozjpeg=false
  only_flif_lossy=false
  only_plots=false
  only_csv=false
  only_image_generation=false
  combine_plots=false
  force_image_generation=false
  target_size=0
  for x in "$@"; do
    if [ "${x: 0:2}" == "--" ]; then
      has_options=true
      break
    fi
  done

  if [ "$has_options" = true ]; then

    for x in "$@"; do

      #skip if not an option
      if [ "${x: 0:2}" != "--" ]; then
        continue
      fi


      if [ "$x" == "--only-libjpeg" ]; then
        only_libjpeg=true
        continue
      fi

      if [ "$x" == "--only-libjpeg-2000" ]; then
        only_libjpeg_2000=true
        continue
      fi

      if [ "$x" == "--only-guetzli" ]; then
        only_guetzli=true
        continue
      fi

      if [ "$x" == "--only-pik" ]; then
        only_pik=true
        continue
      fi

      if [ "$x" == "--only-av1" ]; then
        only_av1=true
        continue
      fi

      if [ "$x" == "--only-webp" ]; then
        only_webp=true
        continue
      fi

      if [ "$x" == "--only-flif-lossy" ]; then
        only_flif_lossy=true
        continue
      fi

      if [ "$x" == "--only-webp-lossy" ]; then
        only_webp_lossy=true
        continue
      fi

      if [ "$x" == "--only-bpg-lossy-jctvc" ]; then
        only_bpg_lossy_jctvc=true
        continue
      fi

      if [ "$x" == "--only-bpg-lossy" ]; then
        only_bpg_lossy=true
        continue
      fi


      if [ "$x" == "--only-mozjpeg" ]; then
        only_mozjpeg=true
        continue
      fi


      if [ "$x" == "--only-plots" ]; then
        only_plots=true
        continue
      fi

      if [ "$x" == "--only-csv" ]; then
        only_csv=true
        continue
      fi


      if [ "$x" == "--combine-plots" ]; then
        combine_plots=true
        continue
      fi

      if [[ "$x" =~ ^--heatmap_target_size=.* ]] ; then
        #set target_size
        target_size=${x//[!0-9]/}
        continue
      fi

      if [ "$x" == "--only-image-generation" ]; then
        only_image_generation=true
        continue
      fi

      if [ "$x" == "--force-image-generation" ]; then
        force_image_generation=true
        continue
      fi

    done

    if [ "$target_size" -gt 0 ]; then
      #delete comparison csv
      for x in "$@"; do
        if [ "${x: 0:2}" == "--" ]; then
          continue
        fi
        filename=$(basename "$x")
        rm -rf  comparision-"$filename".csv
      done

    fi

  fi


  image_list=()
  for x in "$@"; do
    #skip if we are not dealing with an image
    if [ "${x: 0:2}" == "--" ]; then
      continue
    fi
    image_list+=("$x")
  done

  image_count=0
  files_to_zip=()
  list_pik=()
  list_libjpeg=()
  list_libjpeg2000=()
  list_guetzli=()
  list_flif_lossy=()
  list_bpg=()
  list_bpg_jctvc=()
  list_mozjpeg=()
  list_av1=()
  list_webp=()
  list_webp_lossy=()
  list_global_operations=()
  for x in "$@"; do
    #skip if we are not dealing with an image
    if [ "${x: 0:2}" == "--" ]; then
      continue
    fi

    filename=$(basename "$x")
    export only_csv

    if [ ! -e "$filename".ppm ] || [ ! -e  "$filename"_libjpeg_reference.jpg ]; then
      list_global_operations+=("$x")
    fi

    if [ "$only_libjpeg" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "libjpeg-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_libjpeg+=("$x")
      fi
    fi


    if [ "$only_libjpeg_2000" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "libjpeg2000-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_libjpeg2000+=("$x")
      fi
    fi

    if [ "$only_mozjpeg" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "mozjpeg-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_mozjpeg+=("$x")
      fi
    fi

    if [ "$only_pik" = true ] || [ "$only_csv" = true ]  || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "pik-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_pik+=("$x")
      fi
    fi

    if [ "$only_webp" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "webp-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_webp+=("$x")
      fi
    fi

    if [ "$only_webp_lossy" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "webp_lossy-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_webp_lossy+=("$x")
      fi
    fi

    if [ "$only_bpg_lossy" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "bpg-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_bpg+=("$x")
      fi
    fi

    if [ "$only_bpg_lossy_jctvc" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "bpg_jctvc-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_bpg_jctvc+=("$x")
      fi
    fi

    if [ "$only_flif_lossy" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "flif_lossy-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_flif_lossy+=("$x")
      fi
    fi

    if [ "$only_av1" = true ] || [ "$only_csv" = true ] || [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "av1-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_av1+=("$x")
      fi
    fi

    if [ "$only_guetzli" = true ] || [ "$only_csv" = true ] ||  [ "$combine_plots" = true ] || [ "$has_options" = false ]; then
      if [ "$combine_plots" = true ] && [ -e "guetzli-$filename.csv" ] && [ "$only_csv" = false ] && [ "$force_image_generation" = false ]; then
        #Do nothing
        #We don't want to regenerate images and csv files in this special case
        true
      else
        list_guetzli+=("$x")
      fi
    fi

  done

  #Perform the image generation with each encoder in turn
  #This ensures maximum usage of the CPU for slow encoders i.e guetzli and av1

  if [[ "${list_global_operations[@]}" ]]; then
    export -f global_operations
    parallel --will-cite --load 100% -k 'global_operations {1}' ::: "${image_list[@]}"
    sleep 1
  fi

  #LibJPEG
  if [[ "${list_libjpeg[@]}" ]]; then
    export -f libjpeg_test
    parallel --will-cite --load 100%  -k 'libjpeg_test {1}' ::: "${list_libjpeg[@]}"
    sleep 1
  fi

  #OpenJPEG
  if [[ "${list_libjpeg2000[@]}" ]]; then
    export -f libjpeg_2000_test
    parallel --will-cite --load 100%   -k 'libjpeg_2000_test {1}' ::: "${list_libjpeg2000[@]}"
    sleep 1
  fi

  #MozJPEG
  if [[ "${list_mozjpeg[@]}" ]]; then
    export -f mozjpeg_test
    parallel --will-cite --load 100%   -k 'mozjpeg_test {1}' ::: "${list_mozjpeg[@]}"
    sleep 1
  fi

  #Webp
  if [[ "${list_webp[@]}" ]]; then
    export -f webp_near_lossless_test
    parallel --will-cite --load 100%  -k 'webp_near_lossless_test {1}' ::: "${list_webp[@]}"
    sleep 1
  fi


  #Webp lossy
  if [[ "${list_webp_lossy[@]}" ]]; then
    export -f webp_lossy_test
    parallel --will-cite --load 100%   -k 'webp_lossy_test {1}' ::: "${list_webp_lossy[@]}"
    sleep 1
  fi

  #BPG Lossy
  if [[ "${list_bpg[@]}" ]]; then
    export -f bpg_lossy_test
    parallel --will-cite --load 100%   -k 'bpg_lossy_test {1}' ::: "${list_bpg[@]}"
    sleep 1
  fi


  #BPG Lossy JCTVC
  if [[ "${list_bpg_jctvc[@]}" ]]; then
    export -f bpg_lossy_jctvc_test
    parallel --will-cite --load 100%    -k 'bpg_lossy_jctvc_test {1}' ::: "${list_bpg_jctvc[@]}"
    sleep 1
  fi

  #Flif lossy
  if [[ "${list_flif_lossy[@]}" ]]; then
    export -f flif_lossy_test
    parallel --will-cite --load 100%    -k 'flif_lossy_test {1}' ::: "${list_flif_lossy[@]}"
    sleep 1
  fi

  #Pik
  if [[ "${list_pik[@]}" ]]; then
    export -f pik_test
    parallel --will-cite --load 100%   -k 'pik_test {1}' ::: "${list_pik[@]}"
    sleep 1
  fi

  #AV1
  if [[ "${list_av1[@]}" ]]; then
    export -f av1_test
    parallel --will-cite --load 100%   -k 'av1_test {1}' ::: "${list_av1[@]}"
    sleep 1
  fi

  #Guetzli
  if [[ "${list_guetzli[@]}" ]]; then
    export -f guetzli_test
    parallel --will-cite --load 100%   -k 'guetzli_test {1}' ::: "${list_guetzli[@]}"
    sleep 1
  fi

  #Image generation should be done at this point
  #Global operations after image generations happens here
  for x in "$@"; do
    if [ "${x: 0:2}" == "--" ]; then
      continue
    fi
    image_count=$(( image_count + 1 ))
    filename=$(basename "$x")
    # #plot the graphs
    # echo "Generating the plots[Source :$x]"
    # rm -rf "$filename"_butteraugli_plot.png "$filename"_ssimulacra_plot.png
    # reference_jpg_size=$(wc -c < "$filename"_libjpeg_reference.jpg)
    # reference_jpg_bpp=$(convert_to_bpp "$reference_jpg_size")
    # plotcsv_graph "$filename"_butteraugli_plot.png "$filename"  "Source: $filename"
    # plotcsv_graph_ssimulacra "$filename"_ssimulacra_plot.png  "$filename" "Source: $filename"

    #Generate plots in parallel
    export -f generate_single_plots
    parallel --will-cite --load 100% -k 'generate_single_plots {1}' ::: "${image_list[@]}"
    #
    files_to_zip+=("libjpeg-${filename}.csv" "libjpeg2000-${filename}.csv" "guetzli-${filename}.csv" "pik-${filename}.csv" "av1-${filename}.csv" "webp-${filename}.csv" "webp_lossy-${filename}.csv"  "bpg-${filename}.csv" "flif_lossy-${filename}.csv" "mozjpeg-${filename}.csv" "bpg_jctvc-${filename}.csv" "${filename}_butteraugli_plot.png" "${filename}_ssimulacra_plot.png")
    list_pik_csv+=("pik-${filename}.csv")
    list_libjpeg_csv+=("libjpeg-${filename}.csv")
    list_libjpeg2000_csv+=("libjpeg2000-${filename}.csv")
    list_guetzli_csv+=("guetzli-${filename}.csv")
    list_flif_lossy_csv+=("flif_lossy-${filename}.csv")
    list_bpg_csv+=("bpg-${filename}.csv")
    list_bpg_jctvc_csv+=("bpg_jctvc-${filename}.csv")
    list_mozjpeg_csv+=("mozjpeg-${filename}.csv")
    list_av1_csv+=("av1-${filename}.csv")
    list_webp_csv+=("webp-${filename}.csv")
    list_webp_lossy_csv+=("webp_lossy-${filename}.csv")
  done

  #Create merge plots if needed
  if [ "$combine_plots" = true ]; then
    echo "Merging results to create merge plots...."
    rm -rf pik-merge.csv libjpeg-merge.csv libjpeg2000-merge.csv guetzli-merge.csv flif_lossy-merge.csv bpg-merge.csv bpg_jctvc-merge.csv mozjpeg-merge.csv mozjpeg-merge.csv av1-merge.csv webp-merge.csv webp_lossy-merge.csv butteraugli_plot_merge.png ssimulacra_merge ssimulacra_plot_merge.png
    #Create the merge csv
    tail -q -n +4  "${list_pik_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> pik-merge.csv
    tail -q -n +4  "${list_libjpeg_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' |  sort -k1,1 -r -n -t, &> libjpeg-merge.csv
    tail -q -n +4  "${list_libjpeg2000_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> libjpeg2000-merge.csv
    tail -q -n +4  "${list_guetzli_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> guetzli-merge.csv
    tail -q -n +4  "${list_flif_lossy_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> flif_lossy-merge.csv
    tail -q -n +4  "${list_bpg_csv[@]}"  | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> bpg-merge.csv
    tail -q -n +4  "${list_bpg_jctvc_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> bpg_jctvc-merge.csv
    tail -q -n +4  "${list_mozjpeg_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> mozjpeg-merge.csv
    tail -q -n +4  "${list_av1_csv[@]}" | datamash -st, -g1,2 mean 4  mean 5 mean 6 | awk -F , '{printf ("%s,%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4,$5)}' | sort -k1,1 -k2,2 -n  -t,  &> av1-merge.csv
    tail -q -n +4  "${list_webp_csv[@]}" | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> webp-merge.csv
    tail -q -n +4  "${list_webp_lossy_csv[@]}"  | datamash -st, -g1 mean 3  mean 4 mean 5 | awk -F , '{printf ("%s,%.2f,%.6f,%.8f\n",$1,$2,$3,$4)}' | sort -k1,1 -r -n -t, &> webp_lossy-merge.csv

    plotcsv_graph_merge butteraugli_plot_merge.png "Merge Butteraugli Plot( ${image_count} images )"
    plotcsv_graph_ssimulacra_merge ssimulacra_plot_merge.png  "Merge Ssimulacra Plot( ${image_count} images )"
    files_to_zip+=("butteraugli_plot_merge.png" "ssimulacra_plot_merge.png" "pik-merge.csv" "libjpeg-merge.csv" "libjpeg2000-merge.csv" "guetzli-merge.csv" "flif_lossy-merge.csv" "bpg-merge.csv" "bpg_jctvc-merge.csv" "mozjpeg-merge.csv" "mozjpeg-merge.csv" "av1-merge.csv" "webp-merge.csv" "webp_lossy-merge.csv")
  fi



  #Generate heatmap + comparison csv if option is present
  #This is possible only for one image
  #TODO Add parallelism for comparision csv
  if [ "$target_size" -gt 0 ] && [ "$image_count" -eq 1 ]; then

    echo "Generating heatmaps + comparision csv"
    echo "Encoder,Quality,Size(bytes),Size(bpp),Butteraugli,Ssimulacra,PSNR,SSIM,Compression Rate(%),Reference Compression Rate(%)" >> comparision-"$filename".csv

    #pik
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_pik_q"$i".png "$filename"_pik_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_pik_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_pik_q"$i".png /dev/null 2>&1)
        convert "$filename"_pik_q"$i"_hm.ppm "$filename"_pik_q"$i"_hm.png
        files_to_zip+=("${filename}_pik_q${i}_hm.png" "${filename}_pik_q${i}.png")
        echo "Pik","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "pik-$filename.csv" | head -n -3)

    #libjpeg
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_libjpeg_q"$i".jpg "$filename"_libjpeg_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_libjpeg_q"$i".jpg /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_libjpeg_q"$i".jpg /dev/null 2>&1)
        convert "$filename"_libjpeg_q"$i"_hm.ppm "$filename"_libjpeg_q"$i"_hm.png
        files_to_zip+=("${filename}_libjpeg_q${i}_hm.png" "${filename}_libjpeg_q${i}.jpg")
        echo "LibJPEG","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "libjpeg-$filename.csv" | head -n -3)

    #libjpeg2000
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_openjpeg_q"$i".png "$filename"_openjpeg_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_openjpeg_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_openjpeg_q"$i".png /dev/null 2>&1)
        convert "$filename"_openjpeg_q"$i"_hm.ppm "$filename"_openjpeg_q"$i"_hm.png
        files_to_zip+=("${filename}_openjpeg_q${i}_hm.png" "${filename}_openjpeg_q${i}.png")
        echo "OpenJPEG","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "libjpeg2000-$filename.csv" | head -n -3)

    #guetzli
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_guetzli_q"$i".jpg "$filename"_guetzli_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_guetzli_q"$i".jpg /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_guetzli_q"$i".jpg /dev/null 2>&1)
        convert "$filename"_guetzli_q"$i"_hm.ppm "$filename"_guetzli_q"$i"_hm.png
        files_to_zip+=("${filename}_guetzli_q${i}_hm.png" "${filename}_guetzli_q${i}.jpg")
        echo "Guetzli","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "guetzli-$filename.csv" | head -n -3)

    #flif_lossy
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_flif_lossy_q"$i".png "$filename"_flif_lossy_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_flif_lossy_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_flif_lossy_q"$i".png /dev/null 2>&1)
        convert "$filename"_flif_lossy_q"$i"_hm.ppm "$filename"_flif_lossy_q"$i"_hm.png
        files_to_zip+=("${filename}_flif_lossy_q${i}_hm.png"  "${filename}_flif_lossy_q${i}.png")
        echo "Flif Lossy","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "flif_lossy-$filename.csv" | head -n -3)

    #bpg
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_bpg_q"$i".png "$filename"_bpg_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_bpg_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_bpg_q"$i".png /dev/null 2>&1)
        convert "$filename"_bpg_q"$i"_hm.ppm "$filename"_bpg_q"$i"_hm.png
        files_to_zip+=("${filename}_bpg_q${i}_hm.png" "${filename}_bpg_q${i}.png")
        echo "BPG(x265) Lossy","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "bpg-$filename.csv" | head -n -3)

    #bpg jctvc
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_bpg_jctvc_q"$i".png "$filename"_bpg_jctvc_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_bpg_jctvc_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_bpg_jctvc_q"$i".png /dev/null 2>&1)
        convert "$filename"_bpg_jctvc_q"$i"_hm.ppm "$filename"_bpg_jctvc_q"$i"_hm.png
        files_to_zip+=("${filename}_bpg_jctvc_q${i}_hm.png" "${filename}_bpg_jctvc_q${i}.png")
        echo "BPG(jctvc) Lossy","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "bpg_jctvc-$filename.csv" | head -n -3)

    #mozjpeg
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_mozjpeg_q"$i".jpg "$filename"_mozjpeg_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR "$x" "$filename"_mozjpeg_q"$i".jpg /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM "$x" "$filename"_mozjpeg_q"$i".jpg /dev/null 2>&1)
        convert "$filename"_mozjpeg_q"$i"_hm.ppm  "$filename"_mozjpeg_q"$i"_hm.png
        files_to_zip+=("${filename}_mozjpeg_q${i}_hm.png" "${filename}_mozjpeg_q${i}.jpg")
        echo "MozJPEG","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "mozjpeg-$filename.csv" | head -n -3)

    #av1
    while read -r line
    do
      q=$(echo "$line" | cut -d',' -f1)
      i=$(echo "$line" | cut -d',' -f2)
      new_size=$(echo "$line" | cut -d',' -f3) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f4)
      butteraugli_score=$(echo "$line" | cut -d',' -f5)
      ssimulacra_score=$(echo "$line" | cut -d',' -f6)
      compression_rate=$(echo "$line" | cut -d',' -f7)
      reference_compression_rate=$(echo "$line" | cut -d',' -f8)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$x"_"$q"_"$i".png "$x"_"$q"_"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR  "$x" "$x"_"$q"_"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM  "$x" "$x"_"$q"_"$i".png /dev/null 2>&1)
        convert "$x"_"$q"_"$i"_hm.ppm "$x"_"$q"_"$i"_hm.png
        files_to_zip+=("${x}_${q}_${i}_hm.png" "${x}_${q}_${i}.png")
        echo "AV1","$q-$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "av1-$filename.csv" | head -n -3 | sort  -k3,3 -n -t,)


    #webp lossy
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_webp_lossy_q"$i".png "$filename"_webp_lossy_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR  "$x" "$filename"_webp_lossy_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM  "$x" "$filename"_webp_lossy_q"$i".png /dev/null 2>&1)
        convert "$filename"_webp_lossy_q"$i"_hm.ppm "$filename"_webp_lossy_q"$i"_hm.png
        files_to_zip+=("${filename}_webp_lossy_q${i}.png" "${filename}_webp_lossy_q${i}_hm.png")
        echo "Webp(Lossy)","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "webp_lossy-$filename.csv" | head -n -3)


    #webp
    while read -r line
    do
      i=$(echo "$line" | cut -d',' -f1) #get quality
      new_size=$(echo "$line" | cut -d',' -f2) #get size
      new_size_bpp=$(echo "$line" | cut -d',' -f3)
      butteraugli_score=$(echo "$line" | cut -d',' -f4)
      ssimulacra_score=$(echo "$line" | cut -d',' -f5)
      compression_rate=$(echo "$line" | cut -d',' -f6)
      reference_compression_rate=$(echo "$line" | cut -d',' -f7)
      #New size >= target_size
      if [ "$new_size" -ge "$target_size" ]; then
        butteraugli_score=$(butteraugli "$x" "$filename"_webp_q"$i".png "$filename"_webp_q"$i"_hm.ppm)
        psnr_score=$(compare -metric PSNR  "$x" "$filename"_webp_q"$i".png /dev/null 2>&1)
        ssim_score=$(compare -metric SSIM  "$x" "$filename"_webp_q"$i".png /dev/null 2>&1)
        convert "$filename"_webp_q"$i"_hm.ppm "$filename"_webp_q"$i"_hm.png
        files_to_zip+=("${filename}_webp_q${i}.png" "${filename}_webp_q${i}_hm.png")
        echo "Webp","$i","$new_size","$new_size_bpp","$butteraugli_score","$ssimulacra_score","$psnr_score","$ssim_score","$compression_rate","$reference_compression_rate" >> comparision-"$filename".csv
        break
      fi
    done < <(tac "webp-$filename.csv" | head -n -3)

    sort  -k3 -n -t, comparision-"$filename".csv -o comparision-"$filename".csv # sort the csv by filesize
    files_to_zip+=("comparision-$filename.csv")

  fi

  #Create a zip to store the results
  zipfile_name=result_corpus_with_plots$(date "+%Y.%m.%d-%H.%M.%S").zip
  zip "$zipfile_name" "${files_to_zip[@]}"
  current_dir=$(pwd)/"$zipfile_name"
  echo "Success! Download results : $current_dir"
}

main "$@"
