#!/bin/sh

cd /data/prod/logs/webalizer
ls usage_20????.html|sort|sed 's%^usage_\(....\)\(..\).*$%\1/\2%' > data.csv

cnt=0

for i in "Total (des )?Hits" "Total (Files|des Fichiers)" "Total Pages" "Total Visite?s" "Total (Unique Sites|des Sites uniques)" "Total (Unique URLs|des URLs uniques)" "Total (KBytes|kB Files)" "Total (Unique User Agents|des Navigateurs)"
do
	cnt=$((cnt+1))
	grep -A1 -E "${i}" usage_20????.html|sort|sed '/<B>/!d;s%^\([^-]*\)-.*<B>\(.*\)</B>.*$%\2%' > "gruik_$cnt"
	paste data.csv "gruik_$cnt" > data.csv.new && mv data.csv.new data.csv
	rm "gruik_$cnt"
done

sed -i '1iMonth	Hits	Files	Pages	Visits	Unique Sites	Unique URLs	KBytes	Unique User Agents' data.csv
