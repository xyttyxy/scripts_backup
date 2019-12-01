#!/bin/bash
# Universal launcher for ASE calculators in SDSC Comet Supercomputer
# Author: Yantao Xia
# v0.2 Nov. 20, 2019

# USAGE:
# submit -pe shared 4 -l h_data=4G,h_rt=8:00:00,arch=intel*,highp -p vasp -r filename=CONTCAR -t -i
# options can be given in any order

pwd=`pwd`
# definition of calculator and control wrapper
# identical for a set of structures but different for different systems

# VASP PATHS
############ Checking if MPI error is resolved in new intel library ##########
VASP_ROOT_PATH=$HOME'/bin/'
VASP_STD_PATH=$VASP_ROOT_PATH'vasp_std'
VASP_GAM_PATH=$VASP_ROOT_PATH'vasp_gam'
VASP_PP_PATH=$HOME'/lib/vasp_pot/'

# build.sh IS ACTUAL SUBMISSION (sbatch build.sh)
THIS_DIR=$HOME'/scripts/universal/'
BUILD_FILE=$THIS_DIR'build.sh'
TEMPLATE_FILE=$THIS_DIR'template.sh'
CALC_LOG=$THIS_DIR'calc.log'
cp $TEMPLATE_FILE $BUILD_FILE

# CONTROL FLAGS
HAS_PE=false
HAS_PROG=false
HAS_INPUT=false
HAS_CALC=false
IS_OMP=false
IS_VASP=false
IS_VIEW=false
IS_TEST=false
IS_INTERACTIVE=false
IS_READ=false
IS_GEN=false

# THIS LOOP ONLY SETS FLAGS SO THAT OPTIONS ORDER DONT MATTER
for (( i=1; i<=$#; i++)); do
    # Determine OMP or MPI. Either OpenMP or MPI, not both OpenMP and MPI.
    if [ "${!i}" == "-p" ]; then
	HAS_PROG=true
	# submit.sh needs to know which program to run to set environment correctly
	j=$((i+1))
	str="${!j}"
	if [ "$str" == "vasp_std" ]; then
	    IS_VASP=true
	    PROGRAM="VASP_STD"
	    VASP_PATH=$VASP_STD_PATH
	elif [ "$str" == "vasp_gam" ]; then
	    IS_VASP=true
	    PROGRAM="VASP_GAM"
	    VASP_PATH=$VASP_GAM_PATH
        ######################################
	# GAUSSIAN AMD LAMMPS NOT IMPLEMENTED
	# elif [ "$char" == "gaussian" ]; then
	#     PROGRAM="GAUSSIAN"
	# elif [ "$char" == "lammps" ]; then
	#     PROGRAM="LAMMPS"
	fi
    elif [ "${!i}" == "-pe" ]; then
	# single node only now
	HAS_PE=true
	j=$((i+1))
	k=$((j+1))
	NCORE="${!k}"
	PARTITION="#SBATCH --partition=${!j}"
	CORES="#SBATCH --ntasks-per-node=$NCORE"
	VASP_COMMAND="export VASP_COMMAND='mpirun -np $NCORE $VASP_PATH'"
	PE="$NCORE ${!j}"
	# skip the next two
	((i+=2))
    # Resource list
    elif [ "${!i}" == "-l" ]; then
	rsc_lst_idx=$((i+1))
	RSRCSLST="${!rsc_lst_idx}"
	rsc_lst_arr=(${RSRCSLST//,/ })
	for rsc_str in "${rsc_lst_arr[@]}"; do
	    :
	    rsc_arr=(${rsc_str//=/ })
	    rsc_elm=${rsc_arr[0]}
	    if [ ${rsc_arr[0]} == "h_data" ]; then
		MEMORY="#SBATCH --mem-per-cpu=${rsc_arr[1]}"
	    elif [ ${rsc_arr[0]} == "h_rt" ]; then
		TIME="#SBATCH --time=${rsc_arr[1]}"
	    fi
	done
	
    # Input structures
    elif [ "${!i}" == "-r" ]; then
	HAS_INPUT=true
	j=$((i+1))
	READ_PARAMS="${!j}"
	IS_READ=true
    elif [ "${!i}" == "-g" ]; then
	HAS_INPUT=true
	IS_GEN=true
    # Control options
    elif [ "${!i}" == "-v" ]; then
	IS_VIEW=true
    elif [ "${!i}" == "-t" ]; then
	IS_TEST=true
    elif [ "${!i}" == "-i" ]; then
	HAS_PE=true
	IS_INTERACTIVE=true
    fi
done

CALC=./calc.py
if test -f "$CALC"; then
    HAS_CALC=true
fi

# TEST FLAGS
if [ "$HAS_CALC" = false ]; then
    echo "CALCULATOR NOT FOUND!"
    exit 1
elif [ "$HAS_PE" = false ]; then
    echo "PARALLEL ENVIRONMENT NOT GIVEN!"
    exit 1
elif [ "$HAS_PROG" = false ]; then
    echo "PROGRAM NOT GIVEN!"
    exit 1
elif [ "$HAS_INPUT" = false ]; then
    echo "INPUT GEOMETRY NOT GIVEN!"
    exit 1
fi
    
#########################################################
# GAUSSIAN AMD LAMMPS NOT IMPLEMENTED
# elif [ "$PROGRAM" == "GAUSSIAN" ]; then
#     echo "module load gaussian/g16_sse4" >> $BUILD_FILE
# fi

echo $PARTITION >> $BUILD_FILE
echo $CORES >> $BUILD_FILE
echo $MEMORY >> $BUILD_FILE
echo $TIME >> $BUILD_FILE

echo "source /etc/profile.d/modules.sh" >> $BUILD_FILE
echo "module purge" >> $BUILD_FILE
echo "module load vasp" >> $BUILD_FILE

if [ "$IS_VASP" = true ]; then
    echo $VASP_COMMAND >> $BUILD_FILE
fi

chmod u+x $BUILD_FILE
CMD='python3 $pwd/calc.py'

if [ "$IS_VIEW" = true ]; then
    CMD=$CMD" -v"
fi

if [ "$IS_GEN" = true ]; then
    CMD=$CMD" -g"
elif [ "$IS_READ"  = true ]; then
    CMD=$CMD" -r "$READ_PARAMS
fi

CMD=$CMD" "$PROGRAM_ARG

# IF TESTING TELL PYTHON NOT TO EXECUTE
if [ "$IS_TEST" = true ]; then
    CMD=$CMD" -t"
fi

echo "pwd=`pwd`" >> $BUILD_FILE
echo $CMD >> $BUILD_FILE

# IF TESTING THEN RUN INTERACTIVE OR TEST
if [ "$IS_INTERACTIVE" = true ] || [ "$IS_TEST" = true ]; then
    $BUILD_FILE
else
    SBATCH_RETURN=$(sbatch $BUILD_FILE)
    RETURN_ARR=(${SBATCH_RETURN// / })
    JOBID="${RETURN_ARR[3]}"
    # print job id and working directory to log file
    # also print -l resource list and -pe
    echo -n $JOBID >> $CALC_LOG      # job id
    echo -e -n  '\t' >> $CALC_LOG
    echo -n $PWD >> $CALC_LOG        # workding folder
    echo -e -n  '\t' >> $CALC_LOG
    echo -n $RSRCSLST >> $CALC_LOG   # resource list
    echo -e -n  '\t' >> $CALC_LOG
    echo -n $PE >> $CALC_LOG         # parallel environment
    echo "" >> $CALC_LOG

    echo $JOBID
fi

