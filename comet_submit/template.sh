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
