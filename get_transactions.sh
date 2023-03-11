#!/bin/bash 		

# Description:	Converts pdf files named [month]_statement.pdf to tsv files
#               Can't use csv files because of commas in amounts e.g. 1,000

# Dependencies: tabula (extract tables from pdf)
#               download via ubuntu software --> 'tabula'
#               https://github.com/tabulapdf/tabula-java/wiki/Using-the-command-line-tabula-extractor-tool

# To run:	./get_transactions.sh

# Author: Kenneth O'Neill 5/3/23

#######################################################################################

# # Create tsv files with no other processing
# # NOTE: 2>/dev/null redirects tabula warnings to oblivion
# for FILE in *.pdf; 
# 	do
# 		TSV_OUT=$(echo "$FILE" | awk -F '_' '{print $1"_statement.tsv"}');
# 		tabula -p all -f TSV $FILE 2>/dev/null -o $TSV_OUT
# 	done
# echo Conversion Complete!

# #######################################################################################################

################
### EXPENSES ###
################

# Convert pdf to tsv, extract expenses, handle dates, and print output to temp file
# NOTE: 2>/dev/null redirects tabula warnings to oblivion
echo Processing PDFs for debits ...
for FILE in *.pdf; 
	do
		TSV_OUT=$(echo "$FILE" | awk -F '_' '{print $1"_temp.tsv"}');
		tabula -p all -f TSV $FILE 2>/dev/null | awk -F"\t" 'BEGIN{OFS="\t"}
										{
											if($1 ~ /202[2|3]/ && $2 ~ /^[0-9]+.[0-9]+$/){split($1, array, /202[2|3] /); print array[2], $2}
											else if($2 ~ /^[0-9]+.[0-9]+$/){print $1,$2}
										}

										' > $TSV_OUT;
	done

# Handle POS transactions writes to tsv, and monthly expense files (new column added: month)
for FILE in *temp.tsv
	do
		OUT=$(echo "$FILE" | awk -F '_' '{print $1"_debits.tsv"}');
		MONTH=$(echo "$FILE" | awk -F '_' '{print $1}');
		awk -v month="$MONTH" -F"\t" 'BEGIN{OFS="\t"}
					{	
						{$3=month;}
						if($1 ~ /^POS/){split($1, array, / /); print  $3, array[2] array[3] array[4], $2}
						else {print $3, $1, $2}
					}
					' $FILE | sed 's/,//g' > $OUT;
	done

##############
### INCOME ###
##############

# Convert pdf to tsv, extract income, add month column, print output file
# NOTE: 2>/dev/null redirects tabula warnings to oblivion
echo Processing PDFs for credits ...
for FILE in *.pdf; 
	do
		TSV_OUT=$(echo "$FILE" | awk -F '_' '{print $1"_credits.tsv"}');
        MONTH=$(echo "$FILE" | awk -F '_' '{print $1}');
		tabula -p all -f TSV $FILE 2>/dev/null | awk -v month="$MONTH" -F"\t" 'BEGIN{OFS="\t"}
										{
                                            {$4=month;}
                                            if($3 ~ /^SUBTOTAL/){next}
                                            else if($1 ~ /202[2|3]/ && $3 ~ /\.[0-9]+$/){split($1, array, /202[2|3] /); print $4, array[2], $3}
                                            else if($3 ~ /\.[0-9]+$/){print $4, $1, $3}
										}

										' | sed 's/,//g'> $TSV_OUT;
	done

# Create final output files
echo Creating final output files
cat *debits.tsv | sort -t $'\t' -k3,3n -k1,1 > all_debits_sorted_by_price.tsv 					    # sorts debits by price (numerical) then month
sort -t $'\t' -k2,2 -k1,1  all_debits_sorted_by_price.tsv > all_debits_sorted_by_name.tsv 		    # sorts debits by name then month
cat *credits.tsv | sort -t $'\t' -k1,1 > all_credits_sorted_by_month.tsv 			                # sorts credits by month
sort -t $'\t' -k2,2 -k1,1  all_credits_sorted_by_month.tsv > all_credits_sorted_by_name.tsv         # sorts credits by name then month
awk -F"\t" 'BEGIN{OFS="\t"}{if($2 ~ /^COX/){print $0}}' all_credits_sorted_by_month.tsv > income_from_employment.tsv     # income from employment

# Cleanup directories
echo Cleaning up ...
rm *temp.tsv *debits.tsv *credits.tsv
rm -r Out && mkdir Out && mv *.tsv ./Out
echo All Done!



##########################################
# # Get monthly income from employment
# for FILE in *_credits.tsv;
#     do
#     TSV_OUT=$(echo "$FILE" | awk -F '_' '{print $1"_credits.tsv"}');
#     done

# # awk -F"\t" '{ sum += $3} END { print sum }' income_from_employment.tsv

