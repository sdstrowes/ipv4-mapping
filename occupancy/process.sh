#!/bin/bash

# curl http://routeviews.org/bgpdata/2002.05/RIBS/rib.20020510.0008.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20050510.prefixes
# curl http://routeviews.org/bgpdata/2003.05/RIBS/rib.20030510.0012.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20030510.prefixes
# curl http://routeviews.org/bgpdata/2004.05/RIBS/rib.20040510.0019.bz2 | bzcat | ./bgpdump -m - |
# awk -F\| '{if ($7 != "3277 8482 28968 3246") {print $6}}' |
# uniq > data/20040510.prefixes
# curl http://routeviews.org/bgpdata/2005.05/RIBS/rib.20050510.0029.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20050510.prefixes
# curl http://routeviews.org/bgpdata/2006.05/RIBS/rib.20060510.0153.bz2 | bzcat | ./bgpdump -m - |
# awk -F\| '{if ($7 != "2905 701 1660") {print $6}}' |
# uniq > data/20060510.prefixes
# curl http://routeviews.org/bgpdata/2007.05/RIBS/rib.20070510.0159.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20070510.prefixes
# curl http://routeviews.org/bgpdata/2008.05/RIBS/rib.20080510.0057.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20080510.prefixes
# curl http://routeviews.org/bgpdata/2009.05/RIBS/rib.20090510.0159.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20090510.prefixes
# curl http://routeviews.org/bgpdata/2010.05/RIBS/rib.20100510.0000.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20100510.prefixes
# curl http://routeviews.org/bgpdata/2011.05/RIBS/rib.20110510.0000.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20110510.prefixes
# curl http://routeviews.org/bgpdata/2012.05/RIBS/rib.20120510.0000.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20120510.prefixes
# curl http://routeviews.org/bgpdata/2013.05/RIBS/rib.20130510.0000.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20130510.prefixes
# curl http://routeviews.org/bgpdata/2014.05/RIBS/rib.20140510.0000.bz2 | bzcat | ./bgpdump -m - | awk -F\| '{print $6}' | uniq > data/20140510.prefixes

kill_workers() {
	echo ""
	for w in `pgrep -P $$`; do
		echo "Terminating $w"
		kill $w
	done
}

trap "kill_workers; exit 0" INT

for f in data/*.prefixes ; do
	date=`echo $f | egrep -o "[0-9]{8}"`
	cat $f |
	./netsplit.pl |
	awk -v date=$date '{print date,$0}' &
	echo "Spawned worker" > /dev/stderr
done > data/gp.input

for w in `jobs -p`; do
	wait $w
	echo "Worker $w complete"
done

gnuplot_preamble='
 set term pngcairo size 800,500 dashed;
 set xdata time;
 set timefmt "%Y%m%d";
 set format x "%b %Y";
 set xtics rotate "20020510",31557600;
 set xrange ["20020501":"20140518"];
 set border 3;
 set grid;
 set tics nomirror;

 set linestyle 1 lt 1 lw 2 lc rgb "#1f77b4";
 set linestyle 2 lt 1 lw 2 lc rgb "#ff7f0e";
 set linestyle 3 lt 1 lw 2 lc rgb "#2ca02c";
 set linestyle 4 lt 1 lw 2 lc rgb "#d62728";
 set linestyle 5 lt 1 lw 2 lc rgb "#853ab0";
 set linestyle 6 lt 1 lw 2 lc rgb "#3aa8b0";
 set linestyle 7 lt 1 lw 2 lc rgb "#000000";
'

gnuplot <<EOF
 $gnuplot_preamble
 set yrange [0:100];
 set ytics 0,10;
 set ylabel "Percentage advertised";
 set key at 150000000,95
 set out "occupancy-relative.png";
 plot '<grep ARIN    data/gp.input' using 1:3 w lines ls 1 ti "ARIN",\
      '<grep APNIC   data/gp.input' using 1:3 w lines ls 2 ti "APNIC",\
      '<grep RIPE    data/gp.input' using 1:3 w lines ls 3 ti "RIPE NCC",\
      '<grep LACNIC  data/gp.input' using 1:3 w lines ls 4 ti "LACNIC",\
      '<grep AFRINIC data/gp.input' using 1:3 w lines ls 5 ti "AfriNIC",\
      '<grep LEGACY  data/gp.input' using 1:3 w lines ls 6 ti "Legacy",\
      '<grep TOTAL   data/gp.input' using 1:3 w lines ls 7 ti "Total"
EOF

gnuplot <<EOF
 $gnuplot_preamble
 set format y "%.0f"
 set ylabel "Number of /8s";
 set yrange [0:256]
 set ytics 0,16
 set arrow 1 lw 0.5 lt 2 lc rgb "#000000" from graph 0,first 220.67 to graph 1,first 220.67 nohead 
 set key at 150000000,210
 set out "occupancy-absolute.png";
 plot '<grep ARIN    data/gp.input' using 1:(\$4/16777216) w lines ls 1 ti "ARIN",\
      '<grep APNIC   data/gp.input' using 1:(\$4/16777216) w lines ls 2 ti "APNIC",\
      '<grep RIPE    data/gp.input' using 1:(\$4/16777216) w lines ls 3 ti "RIPE NCC",\
      '<grep LACNIC  data/gp.input' using 1:(\$4/16777216) w lines ls 4 ti "LACNIC",\
      '<grep AFRINIC data/gp.input' using 1:(\$4/16777216) w lines ls 5 ti "AfriNIC",\
      '<grep LEGACY  data/gp.input' using 1:(\$4/16777216) w lines ls 6 ti "Legacy",\
      '<grep TOTAL   data/gp.input' using 1:(\$4/16777216) w lines ls 7 ti "Total"
EOF

