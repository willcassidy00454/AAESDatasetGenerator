#%% Imports
import random

from treble_tsdk.tsdk import TSDK
from treble_tsdk import display_data as dd
from treble_tsdk import treble

tsdk = TSDK()

import numpy as np

#%% Function definitions
def readDatToArray(read_dir):
    return np.array(np.genfromtxt(read_dir,
                     skip_header=0,
                     skip_footer=0,
                     names=True,
                     dtype=None,
                     delimiter=",").tolist())


def readCsvToArray(read_dir):
    return np.genfromtxt(read_dir, dtype=str, delimiter=",")


#%% Load room dims and surface materials
num_rooms = 3

# Indices: (room_index, dimension (x/y/z))
room_dimensions = np.empty((num_rooms,3))

for room_index in range(num_rooms):
    room_dimensions[room_index] = readDatToArray(f"Simulation Parameters/Room Dimensions/room_dimensions_{room_index + 1}.dat")

# Load surface materials
# Indices: (room_index, surface_index (front/rear/left/right/floor/ceiling))


#%% Load transducer coords, transducer directivities, and transducer rotations
num_sources = 1
num_receivers = 1
num_ls = 16
num_mics = 16

# Indices: (room_index, transducer_index, dimension (x/y/z))
src_coords = np.empty((num_rooms, num_sources, 3))
rec_coords = np.empty((num_rooms, num_receivers, 3))
ls_coords = np.empty((num_rooms, num_ls, 3))
mic_coords = np.empty((num_rooms, num_mics, 3))

for room_index in range(num_rooms):
    src_coords[room_index] = readDatToArray(f"Simulation Parameters/Transducer Coordinates/src_coords_{room_index + 1}.dat")
    rec_coords[room_index] = readDatToArray(f"Simulation Parameters/Transducer Coordinates/rec_coords_{room_index + 1}.dat")
    ls_coords[room_index] = readDatToArray(f"Simulation Parameters/Transducer Coordinates/ls_coords_{room_index + 1}.dat")
    mic_coords[room_index] = readDatToArray(f"Simulation Parameters/Transducer Coordinates/mic_coords_{room_index + 1}.dat")

# Indices: (room_index, transducer_index)
ls_directivities = np.empty((num_rooms, num_ls), dtype=object)
mic_directivities = np.empty((num_rooms, num_mics), dtype=object)

# Same src/rec directivities used for all rooms, so indices: (transducer_index)
src_directivities = readCsvToArray("Simulation Parameters/Transducer Directivities/src_directivities.csv")
rec_directivities = readCsvToArray("Simulation Parameters/Transducer Directivities/rec_directivities.csv")

for room_index in range(num_rooms):
    ls_directivities[room_index] = readCsvToArray(f"Simulation Parameters/Transducer Directivities/ls_directivities_{room_index + 1}.csv")
    mic_directivities[room_index] = readCsvToArray(f"Simulation Parameters/Transducer Directivities/mic_directivities_{room_index + 1}.csv")

# Indices: (room_index, transducer_index, euler rotation dimension (x/y/z))
ls_rotations = np.empty((num_rooms, num_ls, 3))
mic_rotations = np.empty((num_rooms, num_mics, 3))

# Src/rec rotations are the same in each room
src_rotations = readDatToArray(f"Simulation Parameters/Transducer Rotations Euler/src_rotations.dat")
rec_rotations = readDatToArray(f"Simulation Parameters/Transducer Rotations Euler/rec_rotations.dat")

for room_index in range(num_rooms):
    ls_rotations[room_index] = readDatToArray(f"Simulation Parameters/Transducer Rotations Euler/ls_rotations_{room_index + 1}.dat")
    mic_rotations[room_index] = readDatToArray(f"Simulation Parameters/Transducer Rotations Euler/mic_rotations_{room_index + 1}.dat")