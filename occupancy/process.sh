#!/bin/bash

# curl http://routeviews.org/bgpdata/2004.05/RIBS/rib.20040510.0019.bz2 |
# bzcat |
# ./bgpdump -m - |
# awk -F\| '{if ($7 != "3277 8482 28968 3246") {print $6}}' |
# uniq > data/20040510.prefixes

#curl http://routeviews.org/bgpdata/2006.05/RIBS/rib.20060510.0153.bz2 |
#./bgpdump -m - |
#awk -F\| '{if ($7 != "2905 701 1660") {print $6}}' |
#uniq > data/20060510.prefixes

kill_workers() {
	echo ""
	for w in `pgrep -P $$`; do
		echo "Terminating $w"
		kill $w
	done
}

trap "kill_workers; exit 0" INT

#for f in data/*.prefixes ; do
#	date=`echo $f | egrep -o "[0-9]{8}"`
#	cat $f |
#	./netsplit.pl |
#	awk -v date=$date '{print date,$0}' &
#	echo "Spawned worker" > /dev/stderr
#done > data/gp.input

for w in `jobs -p`; do
	wait $w
	echo "Worker $w complete"
done

gnuplot_preamble='
 set term pngcairo size 800,600;
 set xdata time;
 set timefmt "%Y%m%d";
 set format x "%b-%Y";
 set xtics rotate "20020510",31557600;
 set xrange ["20020501":"20140518"];
 set border 3;
 set grid;
 set tics nomirror;
 set key top left;
 set xlabel "Date";
 set ylabel "Percentage advertised";

 set linestyle 1 lt 1 lw 2 lc rgb "#1f77b4";
 set linestyle 2 lt 2 lw 2 lc rgb "#ff7f0e";
 set linestyle 3 lt 3 lw 2 lc rgb "#2ca02c";
 set linestyle 4 lt 4 lw 2 lc rgb "#d62728";
 set linestyle 5 lt 5 lw 2 lc rgb "#853ab0";
 set linestyle 6 lt 6 lw 2 lc rgb "#3aa8b0";
 set linestyle 7 lt 7 lw 2 lc rgb "#000000";
'

gnuplot <<EOF
 $gnuplot_preamble
 set yrange [0:100];
 set ytics 0,10;
 set out "occupancy-relative.png";
 plot '<grep LACNIC  data/gp.input' using 1:3 w lines ls 1 ti "LACNIC",\
      '<grep ARIN    data/gp.input' using 1:3 w lines ls 2 ti "ARIN",\
      '<grep RIPE    data/gp.input' using 1:3 w lines ls 3 ti "RIPE",\
      '<grep AFRINIC data/gp.input' using 1:3 w lines ls 4 ti "AfriNIC",\
      '<grep APNIC   data/gp.input' using 1:3 w lines ls 5 ti "APNIC",\
      '<grep LEGACY  data/gp.input' using 1:3 w lines ls 6 ti "Legacy",\
      '<grep TOTAL   data/gp.input' using 1:3 w lines ls 7 ti "Total"
EOF

gnuplot <<EOF
 $gnuplot_preamble
 set yrange [0:*];
 set out "occupancy-absolute.png";
 plot '<grep LACNIC  data/gp.input' using 1:4 w lines ls 1 ti "LACNIC",\
      '<grep ARIN    data/gp.input' using 1:4 w lines ls 2 ti "ARIN",\
      '<grep RIPE    data/gp.input' using 1:4 w lines ls 3 ti "RIPE",\
      '<grep AFRINIC data/gp.input' using 1:4 w lines ls 4 ti "AfriNIC",\
      '<grep APNIC   data/gp.input' using 1:4 w lines ls 5 ti "APNIC",\
      '<grep LEGACY  data/gp.input' using 1:4 w lines ls 6 ti "Legacy",\
      '<grep TOTAL   data/gp.input' using 1:4 w lines ls 7 ti "Total"
EOF

