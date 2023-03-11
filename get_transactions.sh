#!/bin/bash 		

# Description:	Converts pdf files named [month]_statement.pdf to text and csv files

# Dependencies: tabula (extract tables from pdf)
#               download via ubuntu software --> 'tabula'
#               https://github.com/tabulapdf/tabula-java/wiki/Using-the-command-line-tabula-extractor-tool

# To run:	./get_transactions.sh

# Author: Kenneth O'Neill 5/3/23

#######################################################################################

# # Create csv files with no other processing
# # NOTE: 2>/dev/null redirects tabula warnings to oblivion
# for FILE in *.pdf; 
# 	do
# 		CSV_OUT=$(echo "$FILE" | awk -F '_' '{print $1"_statement.csv"}');
# 		tabula -p all $FILE 2>/dev/null -o $CSV_OUT
# 	done
# echo Conversion Complete!

# #######################################################################################################

# Convert pdf to csv, extract expenses, handle dates, and print output to temp file
# NOTE: 2>/dev/null redirects tabula warnings to oblivion
echo Processing PDFs ...
for FILE in *.pdf; 
	do
		CSV_OUT=$(echo "$FILE" | awk -F '_' '{print $1"_temp.csv"}');
		tabula -p all $FILE 2>/dev/null | awk -F"," 'BEGIN{OFS=","}
										{
											if($1 ~ /202[2|3]/ && $2 ~ /^[0-9]+.[0-9]+$/){split($1, array, /202[2|3] /); print array[2], $2}
											else if($2 ~ /^[0-9]+.[0-9]+$/){print $1,$2}
										}

										' > $CSV_OUT;
	done

# Handle POS transactions, sorts, writes to csv, and monthly expense files (new column added: month)
for FILE in *temp.csv
	do
		OUT=$(echo "$FILE" | awk -F '_' '{print $1"_expenses.csv"}');
		MONTH=$(echo "$FILE" | awk -F '_' '{print $1}');
		#mydate=$(date)
		#awk -v d="$mydate" -F"," 'BEGIN { OFS = "," } {$6=d; print}' input.csv > output.csv
		awk -v month="$MONTH" -F"," 'BEGIN{OFS=","}
					{	
						{$3=month;}
						if($1 ~ /^POS/){split($1, array, / /); print  $3, array[2] array[3] array[4], $2}
						else {print $3, $1, $2}
					}
					' $FILE | sort > $OUT;
	done

# Create final output files + cleanup directories
cat *expenses.csv | sort -t"," -k3,3n -k1,1 > all_expenses_sorted_by_price.csv 					# sorts by price (numerical) then month
sort -t"," -k2,2 -k1,1  all_expenses_sorted_by_price.csv > all_expenses_sorted_by_name.csv 		# sorts by name then month
rm *temp.csv *expenses.csv
mkdir -p Out && mv *.csv ./Out
echo Done!
