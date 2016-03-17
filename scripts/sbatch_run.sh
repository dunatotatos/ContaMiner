#!/bin/sh

##    Copyright (C) 2016 King Abdullah University of Science and Technology
##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation; either version 2 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License along
##    with this program; if not, write to the Free Software Foundation, Inc.,
##    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
##
## sbatch_run.sh version 1.0.1
## sbatch script to run MoRDa a parse the result

#SBATCH --time=05:00:00
#SBATCH --ntasks=1
#SBATCH --quiet

# Define paths
define_paths="$1"
. "$define_paths"

# Prepare environment
contaminant="$2"
input_file_name="$3"
res_file=$(readlink -f "results.txt")
ipack="$4"
alt_sg="$5"
alt_sg_slug=$(printf "$alt_sg" | sed 's/ /-/g')
task_id=$contaminant"_"$ipack"_"$alt_sg_slug
mkdir -p "$task_id"
output_dir=$(readlink -f "$task_id")
resdir="$output_dir/results_solve"
outdir="$output_dir/out_solve"
scrdir="$output_dir/scr_solve"
model_dir="$contam_path/$contaminant/models"
cd "$output_dir"

# Core job
morda_solve -f "$input_file_name" -m "$model_dir" -p $ipack -sg "$alt_sg" \
-r "$resdir" -po "$outdir" -ps "$scrdir"

# Parse result
xml_file=$resdir"/morda_solve.xml"
log_file=$resdir"/morda_solve.log"
err=$(grep "<err_level>" $xml_file | cut --delimiter=" " -f 8)
elaps_time=$(grep "Elapsed: " $log_file | tail -n 1 | cut --delimiter=":" -f 3)
elaps_time=$(printf "$elaps_time" | tr -d '\n' | sed 's/^\ *//g')
case $err in
    7)
        sed -i "/$task_id:cancelled:/c\\$task_id:nosolution:$elaps_time" $res_file
        ;;
    0)
        # xmllpath outdated, no support of --xpath option...
        q_factor=$(printf "cat //q_factor/text()\n" |\
            xmllint --shell $xml_file | grep -v "/ >" | tr -d [:blank:])

        percent=$(printf "cat //percent/text()\n" |\
            xmllint --shell $xml_file | grep -v "/ >" | tr -d [:blank:])

        seqs=$(printf "cat //line/code_seq/text()\n" |\
            xmllint --shell $xml_file | grep -v "/ >" | grep -v -- "----" |\
            sed 's/ seq //g' | tr -d '\n')
        seqs=$(printf "$seqs" | sed -r 's/((^\ *|\ *$))//g' | sed 's/ /,/g')

        strs=$(printf "cat //line/code_str/text()\n" |\
            xmllint --shell $xml_file | grep -v "/ >" | grep -v -- "----" |\
            sed 's/ seq //g' | tr -d '\n')
        strs=$(printf "$strs" | sed -r 's/((^\ *|\ *$))//g' | sed 's/ /,/g')

        mods=$(printf "cat //line/code_mod/text()\n" |\
            xmllint --shell $xml_file | grep -v "/ >" | grep -v -- "----" |\
            sed 's/ seq //g' | tr -d '\n')
        mods=$(printf "$mods" | sed -r 's/((^\ *|\ *$))//g' | sed 's/ /,/g')

        sed -i "/$task_id:cancelled:/c\\$task_id:$q_factor-$percent-$seqs-$strs-$mods:$elaps_time" $res_file

        ;;
    *)
        sed -i "/$task_id:cancelled:/c\\$task_id:error:$elaps_time" $res_file
        ;;
esac
