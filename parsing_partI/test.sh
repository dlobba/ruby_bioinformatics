#! /bin/bash
program="parsing.rb"
input_dir="input_files";
out_dir="output_files";
_file="M10051"
terminate=0

test -d $input_dir || terminate=1

if [ $terminate -eq 1 ]
then
  echo "Input files missing, abort execution..."
  exit
fi

test -d $out_dir   || mkdir $out_dir;

chmod +x $program

./$program $input_dir/$_file.txt $out_dir/$_file.fa

diff $input_dir/$_file.fa $out_dir/$_file.fa
