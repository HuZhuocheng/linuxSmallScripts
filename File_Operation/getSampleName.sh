#!/bin/bash

# Parse command line options
sort_flag="no" # Default is not to sort
middlepattern="" # Default middle pattern is empty
maxdepth_option="-maxdepth 1" # Default is not to recurse

while getopts ":p:t:o:m:sr" opt; do
  case ${opt} in
    p ) path=${OPTARG};;
    t ) filetype=${OPTARG};;
    o ) outputfile=${OPTARG};;
    m ) middlepattern=${OPTARG};; # If -m is provided, set the middle pattern
    s ) sort_flag="yes";; # If -s is provided, set to sort
    r ) maxdepth_option="";; # If -r is provided, perform a recursive search, remove -maxdepth restriction
    \? ) echo "Usage: $0 -p <path> -t <filetype> -o <outputfile> [-m <middlepattern>] [-s] [-r]" >&2
         exit 1 ;;
    : ) echo "Invalid option: -$OPTARG requires an argument" >&2
        exit 1 ;;
  esac
done

# Check if all required parameters are provided
if [ -z "${path}" ] || [ -z "${filetype}" ] || [ -z "${outputfile}" ]; then
  echo "Usage: $0 -p <path> -t <filetype> -o <outputfile> [-m <middlepattern>] [-s] [-r]"
  exit 1
fi

# Create a temporary file to store unsorted sample names
tempfile=$(mktemp)

# Find files and write their names (without the middle part and extension) to the temporary file
find "${path}" ${maxdepth_option} -type f -name "*.${filetype}" | while read -r file; do
  # Get the filename without path and extension
  filename=$(basename -- "${file}")
  filename="${filename%.*}" # Remove extension

  # If a middle pattern is provided, use it to remove unwanted parts
  if [[ -n "${middlepattern}" ]]; then
    sample_name="${filename%%${middlepattern}*}" # Remove from first occurrence of middlepattern to end
  else
    sample_name="${filename}"
  fi

  # Write to the temporary file, ensuring only non-empty sample names are written
  if [[ -n "${sample_name}" ]]; then
    echo "${sample_name}" >> "${tempfile}"
  fi
done

# Decide whether to sort the sample names in the temporary file based on sort_flag
if [ "${sort_flag}" == "yes" ]; then
  # Sort the sample names in the temporary file, remove duplicates, and write to the final output file
  sort "${tempfile}" | uniq > "${outputfile}"
else
  # Do not sort, directly write the contents to the final output file
  cat "${tempfile}" > "${outputfile}"
fi

# Delete the temporary file
rm "${tempfile}"

echo "Sample names have been written to ${outputfile}, sorted: ${sort_flag}"
