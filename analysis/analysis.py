# script to check for convergence and print energies
# as a replacement for executing for i in *; do grep..
from ase.calculators.vasp import Vasp, Vasp2
from myase.calculators.gaussian import Gaussian
import os, warnings

warnings.simplefilter('ignore')
# ASE reading existing calculation into a calculator.
# VASP2(FileIOCalculator) is a lot (3X) faster
def check_convergence():
    dirs = next(os.walk('.'))[1]
    #dirs.reverse()
    paths = []
    energies = []
    for i in dirs:
        if '__' in i:
            continue
        elif i[0] != 't':
            continue
        pwd = os.getcwd()
        os.chdir(i)
        try:
            calc = Vasp2(restart=True)
            atoms = calc.get_atoms()
            if calc.converged:
                energy = calc.get_potential_energy(atoms)
                paths.append(i)
                energies.append(energy)
                print("{:<10} {:<20} {:<15}".format(i+'/', "CONVERGED:", energy))
            else:
                print("{:<10} {:<20}".format(i+'/', "NOT CONVERGED!"))

        except FileNotFoundError: 
            print("{:<10} {:<20}".format(i+'/', "FILES NOT FOUND!"))
        except:
            print("{:<10} {:<20}".format(i+'/', "RUNNING!"))

        os.chdir(pwd)
    if energies:
        min_idx = energies.index(min(energies))
        print("Minimum is {} at {}".format(paths[min_idx], energies[min_idx]))
        
    



