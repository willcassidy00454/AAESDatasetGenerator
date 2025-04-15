#%% Imports
import warnings

from treble_tsdk.tsdk import TSDK
from treble_tsdk import display_data as dd
from treble_tsdk import treble
import numpy as np

tsdk = TSDK()

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


#%% Load room dims and make material assignments
num_rooms = 3

# Indices: (room_index, dimension (x/y/z))
room_dimensions = np.empty((num_rooms,3))

for room_index in range(num_rooms):
    room_dimensions[room_index] = readDatToArray(f"Simulation Parameters/Room Dimensions/room_dimensions_{room_index + 1}.dat")

# Indices: (room_index, surface_index (walls/floor/ceiling))
surface_material_ids = np.empty((num_rooms, 3), dtype=object)

for room_index in range(num_rooms):
    surface_material_ids[room_index] = readCsvToArray(f"Simulation Parameters/Surface Materials/surface_materials_{room_index + 1}.csv")

# Indices: (room_index, surface_index (walls/floor/ceiling))
material_assignments = [[] for i in range(num_rooms)]
layers = ["angledShoebox_walls", "angledShoebox_floor", "angledShoebox_ceiling"]

for room_index in range(num_rooms):
    for surface_index in range(3):
        layer = layers[surface_index]
        material = tsdk.material_library.get_by_id(surface_material_ids[room_index][surface_index])
        material_assignments[room_index].append(treble.MaterialAssignment(layer, material))

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

# Indices: (room_index, transducer_index, polar index (az, el))
ls_rotations = np.empty((num_rooms, num_ls, 2))
mic_rotations = np.empty((num_rooms, num_mics, 2))

# Src/rec rotations are the same in each room, so indices: (polar index (az, el))
src_rotations = readDatToArray(f"Simulation Parameters/Transducer Rotations/src_rotations.dat")
rec_rotations = readDatToArray(f"Simulation Parameters/Transducer Rotations/rec_rotations.dat")

for room_index in range(num_rooms):
    ls_rotations[room_index] = readDatToArray(f"Simulation Parameters/Transducer Rotations/ls_rotations_{room_index + 1}.dat")
    mic_rotations[room_index] = readDatToArray(f"Simulation Parameters/Transducer Rotations/mic_rotations_{room_index + 1}.dat")

#%% Create rooms
rooms = []

for room_index in range(num_rooms):
    rooms.append(treble.GeometryDefinitionGenerator.create_angled_shoebox_room(
        base_side=float(room_dimensions[room_index][0]),
        depth_y=float(room_dimensions[room_index][1]),
        height_z=float(room_dimensions[room_index][2]),
        left_angle=89,
        right_angle=91,
        join_wall_layers=True))

# plot the room
# rooms[0].plot()

#%% Define transducers for each room
# Indices: (room_index, transducer_index)
sources = [[] for i in range(num_rooms)]
receivers = [[] for i in range(num_rooms)]
loudspeakers = [[] for i in range(num_rooms)]
microphones = [[] for i in range(num_rooms)]

# It looks like you can't specify the rotation of a spatial receiver
for room_index in range(num_rooms):
    assert src_directivities == "OMNI"
    sources[room_index].append(treble.Source.make_omni(position=treble.Point3d(float(src_coords[room_index][0][0]),
                                                                               float(src_coords[room_index][0][1]),
                                                                               float(src_coords[room_index][0][2])),
                                                       label="source_1"))
    assert rec_directivities == "FOURTH ORDER SH"
    receivers[room_index].append(treble.Receiver.make_spatial(position=treble.Point3d(float(rec_coords[room_index][0][0]),
                                                                                      float(rec_coords[room_index][0][1]),
                                                                                      float(rec_coords[room_index][0][2])),
                                                              label="receiver_1",
                                                              ambisonics_order=4))
    for ls_index in range(num_ls):
        assert ls_directivities[room_index][ls_index] == "CARDIOID"
        loudspeakers[room_index].append(treble.Source.make_cardioid(position=treble.Point3d(float(ls_coords[room_index][ls_index][0]),
                                                                                            float(ls_coords[room_index][ls_index][1]),
                                                                                            float(ls_coords[room_index][ls_index][2])),
                                                                    orientation=treble.Rotation(azimuth=float(ls_rotations[room_index][ls_index][0]),
                                                                                                elevation=float(ls_rotations[room_index][ls_index][1])),
                                                                    label=f"ls_{ls_index + 1}"))
    for mic_index in range(num_mics):
        if mic_directivities[room_index][mic_index] == "OMNI":
            microphones[room_index].append(treble.Source.make_omni(position=treble.Point3d(float(mic_coords[room_index][mic_index][0]),
                                                                                           float(mic_coords[room_index][mic_index][1]),
                                                                                           float(mic_coords[room_index][mic_index][2])),
                                                                    label=f"mic_{mic_index + 1}"))
        elif mic_directivities[room_index][mic_index] == "CARDIOID":
            microphones[room_index].append(treble.Source.make_cardioid(position=treble.Point3d(float(mic_coords[room_index][mic_index][0]),
                                                                                               float(mic_coords[room_index][mic_index][1]),
                                                                                               float(mic_coords[room_index][mic_index][2])),
                                                                        orientation=treble.Rotation(azimuth=float(mic_rotations[room_index][mic_index][0]),
                                                                                                    elevation=float(mic_rotations[room_index][mic_index][1])),
                                                                        label=f"mic_{mic_index + 1}"))
        else:
            warnings.warn(f"Directivity '{mic_directivities[room_index][mic_index]}' not recognised.")

#%% Create/load project
# tsdk.create_project("AAESPerceptualModelDataset")
project = tsdk.get_by_name("AAESPerceptualModelDataset")

#%% Add/load project models
models = []

for room_index in range(num_rooms):
    # models.append(project.add_model(f"room_{room_index + 1}", rooms[room_index]))
    models.append(project.get_model_by_name(f"room_{room_index + 1}"))

#%% Create simulation definition for validating the reverberation times of each room
estimated_t60 = 2.5
estimated_volume = 5000.0
schroeder_frequency = 2000.0 * np.sqrt(estimated_t60 / estimated_volume)
crossover_frequency = int(4.0 * schroeder_frequency)

sim_defs = []

for room_index in range(num_rooms):
    sim_defs.append(treble.SimulationDefinition(
            name=f"rt_validation_room_{room_index + 1}", # unique name of the simulation
            simulation_type=treble.SimulationType.hybrid, # the type of simulation
            crossover_frequency=crossover_frequency,
            model=models[room_index], # the model we created in an earlier step
            energy_decay_threshold=40, # simulation termination criteria - the simulation stops running after -40 dB of energy decay
            receiver_list=receivers[room_index],
            source_list=sources[room_index],
            material_assignment=material_assignments[room_index]))

    # double check that all the receivers and sources fall within the room
    sim_defs[room_index].remove_invalid_receivers()
    sim_defs[room_index].remove_invalid_sources()

    # plot the simulation before adding it to the project
    # sim_defs[room_index].plot()

#%% Create simulation definitions for all room conditions and add to project

#%% Add simulations to project
simulations = []

for room_index in range(1):#num_rooms):
    simulations.append(project.add_simulation(sim_defs[room_index]))

#%% Get simulations
simulations = project.get_simulations()

#%% Display simulations
dd.display(project.get_simulations())

#%% Delete simulation
# project.delete_simulation(project.get_simulation("3cb5b491-3b8a-407b-8d9f-954ae49ebb1c"))

#%% Run simulations
for simulation in simulations:
    simulation.start()
    simulation.as_live_progress()

#%% Download/load simulations
results = []

for simulation in simulations:
    # results.append(simulation.download_results(f"Treble/Results/{simulation.name}"))
    results.append(simulation.get_results_object(f"Treble/Results/{simulation.name}"))

#%% Plot results/acoustic params
results[0].plot()
# results[0].get_acoustic_parameters("source_1", "receiver_1").plot()