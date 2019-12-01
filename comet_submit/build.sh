#!/bin/bash
# Template for Universal launcher for ASE calculators in UCLA Hoffman2 Supercomputer
# Author: Yantao Xia
# v0.3 November 20 2019

# USAGE(remove the -t to really submit:
# submit -pe shared 4 -l h_data=4G,h_rt=8:00:00,arch=intel*,highp -t

#SBATCH --output="%j.%N.out"
#SBATCH --export=ALL
#SBATCH --nodes=1
#SBATCH -A cla175
#SBATCH --partition=shared
#SBATCH --ntasks-per-node=8
#SBATCH --mem-per-cpu=1G
#SBATCH --time=24:00:00
source /etc/profile.d/modules.sh
module purge
module load vasp
export VASP_COMMAND='mpirun -np 8 /home/xyttyxyx/bin/vasp_std'
pwd=/oasis/scratch/comet/xyttyxyx/temp_project/coverage_search/Ni/311/2N/t4
python3 $pwd/calc.py -r filename=CONTCAR
