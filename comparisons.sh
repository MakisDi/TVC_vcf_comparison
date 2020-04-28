#!/bin/bash

# INPUT DIRECTORY STRUCTURE:
# 2 BED files
# Two folders named "filtered" and "non_filtered"
# 		N subdirectories, 1 for each sample
# 			2 vcf files: 1 with the 'grpA_' prefix,
# 						 1 with the 'grpB_' prefix

# Functions
usage () {
  printf "USAGE:\n"
  printf "comparisons.sh <path_to_input_dir> <bedA> <bedB> <grpA> <grpB>\n\n"
}

exitWithError () {
  printf "\n***ERROR: $1\n\n"
  usage
  exit
}

# Check params
if [ "$#" -ne 3 ]; then
  exitWithError "Missing parameters"
fi

path="$1"
bedA="$2"
bedB="$3"
grpA="$4"
grpB="$5"

# common kit regions (with minimum required overlap)
bedtools-2.28.0/bin/bedtools intersect -a "$path"/"$bedA" -b "$path"/"$bedB" -wo> common_regions.bed


filtered=("$path"/filtered/*)
non_filtered=("$path"/non_filtered/*)

unset GRP1
unset GRP2

for i in "${filtered[@]}"; do
	declare -a GRP1
	GRP1=($(find "$i" | grep "$grpA\_.*.vcf$"))

	for j in "${GRP1[@]}"; do
		# PMNet variants in common regions
		vcftools --vcf "$j" --bed common_regions.bed --out "$i"/common_regions_"$grpA" --recode --keep-INFO-all
	done

	declare -a GRP2
	GRP2=($(find "$i" | grep "$grpB\_.*.vcf$"))

	for j in "${GRP2[@]}"; do
		# PMNet variants in common regions
		vcftools --vcf "$j" --bed common_regions.bed --out "$i"/common_regions_"$grpB" --recode --keep-INFO-all
	done

	#Common variants in common regions
	bedtools-2.28.0/bin/bedtools intersect -a "$i"/common_regions_"$grpA".recode.vcf -b "$i"/common_regions_"$grpB".recode.vcf -wo> "$i"/common.tsv
	bedtools-2.28.0/bin/bedtools intersect -a "$i"/common_regions_"$grpA".recode.vcf -b "$i"/common_regions_"$grpB".recode.vcf -v> "$i"/"$grpA"_only.tsv
	bedtools-2.28.0/bin/bedtools intersect -b "$i"/common_regions_"$grpA".recode.vcf -a "$i"/common_regions_"$grpB".recode.vcf -v> "$i"/"$grpB"_only.tsv

done

unset GRP1
unset GRP2

for i in "${non_filtered[@]}"; do
	declare -a GRP1
	GRP1=($(find "$i" | grep "$grpA\_.*.vcf$"))

	for j in "${GRP1[@]}"; do
		# PMNet variants in common regions
		vcftools --vcf "$j" --bed common_regions.bed --out "$i"/common_regions_"$grpA" --recode --keep-INFO-all
	done

	declare -a GRP2
	GRP2=($(find "$i" | grep "$grpB\_.*.vcf$"))

	for j in "${GRP2[@]}"; do
		# PMNet variants in common regions
		vcftools --vcf "$j" --bed common_regions.bed --out "$i"/common_regions_"$grpB" --recode --keep-INFO-all
	done

	#Common variants in common regions
	bedtools-2.28.0/bin/bedtools intersect -a "$i"/common_regions_"$grpA".recode.vcf -b "$i"/common_regions_"$grpB".recode.vcf -wo> "$i"/common.tsv
	bedtools-2.28.0/bin/bedtools intersect -a "$i"/common_regions_"$grpA".recode.vcf -b "$i"/common_regions_"$grpB".recode.vcf -v> "$i"/"$grpA"_only.tsv
	bedtools-2.28.0/bin/bedtools intersect -b "$i"/common_regions_"$grpA".recode.vcf -a "$i"/common_regions_"$grpB".recode.vcf -v> "$i"/"$grpB"_only.tsv

done

Rscript -e "path = '$1'; grpA = '$2'; grpB = '$3'; rmarkdown::render('report.Rmd', output_file = paste0(path,'comparisons_report.html'), output_dir = path)"
