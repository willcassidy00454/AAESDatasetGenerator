#%% Imports and function definitions
import warnings

from treble_tsdk.tsdk import TSDK
from treble_tsdk import display_data as dd
from treble_tsdk import treble
import numpy as np

tsdk = TSDK()

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
material_assignments = [[] for i in range(num_rooms)]
layer_names = ["angledShoebox_wall_0", "angledShoebox_wall_1", "angledShoebox_wall_2", "angledShoebox_wall_3", "angledShoebox_floor", "angledShoebox_ceiling"]
corresponding_surfaces = ["non_frontal_wall", "non_frontal_wall", "non_frontal_wall", "front_wall", "floor", "ceiling"]

for room_index in range(num_rooms):
    for layer_index in range(len(layer_names)):
        layer_name = layer_names[layer_index]
        # get_by_name doesn't seem to work... search does though, but we need one element so take the first
        material = tsdk.material_library.search(f"room_{room_index + 1}_{corresponding_surfaces[layer_index]}")[0]
        material_assignments[room_index].append(treble.MaterialAssignment(layer_name, material))

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

#%% Create rooms (not required if loading models from project)
rooms = []

for room_index in range(num_rooms):
    rooms.append(treble.GeometryDefinitionGenerator.create_angled_shoebox_room(
        base_side=float(room_dimensions[room_index][0]),
        depth_y=float(room_dimensions[room_index][1]),
        height_z=float(room_dimensions[room_index][2]),
        left_angle=89,
        right_angle=91,
        join_wall_layers=False))

# plot the room
# rooms[0].plot()

#%% Full Simulation Only: define transducers for each room
# Indices: (room_index, transducer_index)
sources = [[] for i in range(num_rooms)]
receivers = [[] for i in range(num_rooms)]
loudspeakers = [[] for i in range(num_rooms)]
microphones = [[] for i in range(num_rooms)]

ls_directivity_model = tsdk.source_directivity_library.query(name="8020")[0] # # # # placeholder

for room_index in range(num_rooms):
    assert src_directivities == "OMNI"
    sources[room_index].append(treble.Source.make_omni(position=treble.Point3d(float(src_coords[room_index][0][0]),
                                                                               float(src_coords[room_index][0][1]),
                                                                               float(src_coords[room_index][0][2])),
                                                       label="source_1"))

    # It looks like you don't specify the rotation of a spatial receiver, so this will need doing at reproduction
    assert rec_directivities == "FOURTH ORDER SH"
    receivers[room_index].append(treble.Receiver.make_spatial(position=treble.Point3d(float(rec_coords[room_index][0][0]),
                                                                                      float(rec_coords[room_index][0][1]),
                                                                                      float(rec_coords[room_index][0][2])),
                                                              label="receiver_1",
                                                              ambisonics_order=4))
    for ls_index in range(num_ls):
        assert ls_directivities[room_index][ls_index] == "CARDIOID"
        loudspeakers[room_index].append(treble.Source.make_directive(position=treble.Point3d(float(ls_coords[room_index][ls_index][0]),
                                                                                            float(ls_coords[room_index][ls_index][1]),
                                                                                            float(ls_coords[room_index][ls_index][2])),
                                                                     orientation=treble.Rotation(azimuth=float(ls_rotations[room_index][ls_index][0]),
                                                                                                 elevation=float(ls_rotations[room_index][ls_index][1])),
                                                                     label=f"ls_{ls_index + 1}",
                                                                     source_directivity=ls_directivity_model))
    for mic_index in range(num_mics):
        # For both cardioid and omni mics, use first-order SHs as these will be modelled spatially.
        # These need to be post-processed to extract the device IRs with the correct rotation applied
        if mic_directivities[room_index][mic_index] == "CARDIOID" or mic_directivities[room_index][mic_index] == "OMNI":
            microphones[room_index].append(treble.Receiver.make_spatial(position=treble.Point3d(float(mic_coords[room_index][mic_index][0]),
                                                                                               float(mic_coords[room_index][mic_index][1]),
                                                                                               float(mic_coords[room_index][mic_index][2])),
                                                                        label=f"mic_{mic_index + 1}",
                                                                        ambisonics_order=1))
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

#%% RT Validation: create simulation definition for validating the reverberation times of each room
room_index_to_validate = 2 # Starts at 0

estimated_t60s = [1.5, 1.5, 2.0]
estimated_volumes = [900.0, 8000.0, 6100.0]
schroeder_frequency = 2000.0 * np.sqrt(estimated_t60s[room_index_to_validate] / estimated_volumes[room_index_to_validate])
crossover_frequency = int(4.0 * schroeder_frequency)

sim_defs = [(treble.SimulationDefinition(
        name=f"rt_validation_room_{room_index_to_validate + 1}", # unique name of the simulation
        simulation_type=treble.SimulationType.hybrid, # the type of simulation
        crossover_frequency=crossover_frequency,
        model=models[room_index_to_validate], # the model we created in an earlier step
        energy_decay_threshold=40, # simulation termination criteria - the simulation stops running after -40 dB of energy decay
        receiver_list=[treble.Receiver.make_mono(position=treble.Point3d(float(rec_coords[room_index_to_validate][0][0]),
                                                                         float(rec_coords[room_index_to_validate][0][1]),
                                                                         float(rec_coords[room_index_to_validate][0][2])),
                                                 label="receiver_1")],
        source_list=[treble.Source.make_omni(position=treble.Point3d(float(src_coords[room_index_to_validate][0][0]),
                                                                     float(src_coords[room_index_to_validate][0][1]),
                                                                     float(src_coords[room_index_to_validate][0][2])),
                                             label="source_1")],
        material_assignment=material_assignments[room_index_to_validate]))]

# double check that all the receivers and sources fall within the room
sim_defs[0].remove_invalid_receivers()
sim_defs[0].remove_invalid_sources()

# plot the simulation before adding it to the project
# sim_defs[0].plot()

#%% Full Simulation: create simulation definitions for all room conditions
sim_defs = []

for room_index in range(num_rooms):
    estimated_t60s = [1.5, 1.5, 2.0]
    estimated_volumes = [900.0, 8000.0, 6100.0]
    schroeder_frequency = 2000.0 * np.sqrt(estimated_t60s[room_index] / estimated_volumes[room_index])
    crossover_frequency = int(4.0 * schroeder_frequency)

    sim_defs.append(treble.SimulationDefinition(
            name=f"rt_validation_room_{room_index + 1}", # unique name of the simulation
            simulation_type=treble.SimulationType.hybrid, # the type of simulation
            crossover_frequency=crossover_frequency,
            model=models[room_index], # the model we created in an earlier step
            energy_decay_threshold=40, # simulation termination criteria - the simulation stops running after -40 dB of energy decay
            receiver_list=receivers[room_index] + microphones[room_index],
            source_list=sources[room_index] + loudspeakers[room_index],
            material_assignment=material_assignments[room_index]))

    # double check that all the receivers and sources fall within the room
    sim_defs[room_index].remove_invalid_receivers()
    sim_defs[room_index].remove_invalid_sources()

#%% Plot simulation
sim_defs[2].plot()

#%% Display simulations
dd.display(project.get_simulations())

#%% RT Validation: delete validation simulation
project.delete_simulation(project.get_simulation_by_name(f"rt_validation_room_{room_index_to_validate + 1}"))

#%% Add simulations to project
simulations = []

for sim_index in range(len(sim_defs)):
    simulations.append(project.add_simulation(sim_defs[sim_index]))

#%% Run simulations
for simulation in simulations:
    simulation.start()

# This will log a message when simulations complete
project.as_live_progress()

#%% Download/load simulations
results = []

for simulation in simulations:
    # results.append(simulation.download_results(f"Treble/Results/{simulation.name}"))
    results.append(simulation.get_results_object(f"Treble/Results/{simulation.name}"))

#%% Full Simulation: extract mono IRs from the first-order SH microphone IRs, applying the rotations and DRTFs.
# Save these into a folder with labels "G" (source to mics) and "H" (ls to mics) in the format "G_R1_S1"
microphone_model_omni = tsdk.device_library.get_by_name("microphone_model_omni")
microphone_model_cardioid = tsdk.device_library.get_by_name("microphone_model_cardioid") # # # # these are just placeholders

for room_index in range(num_rooms):
    for mic_index in range(num_mics):
        microphone = microphones[room_index][mic_index]

        if mic_directivities[room_index][mic_index] == "OMNI":
            device_model = microphone_model_omni
        elif mic_directivities[room_index][mic_index] == "CARDIOID":
            device_model = microphone_model_cardioid
        else:
            warnings.warn("Microphone directivity not recognised.")

        # Sources to microphones ("G" matrix):
        for source_index in range(num_sources):
            source = sources[room_index][source_index]

            spatial_ir = results[room_index].get_spatial_ir(source=source, receiver=microphone)
            device_ir = spatial_ir.render_device_ir(device=device_model,
                                                    orientation=treble.Rotation(azimuth=float(mic_rotations[room_index][mic_index][0]),
                                                                                elevation=float(mic_rotations[room_index][mic_index][1])))
            device_ir.write_to_wav(path_to_file=f"Audio Data/Physical RIRs/Room {room_index + 1}/G_R{mic_index}_S{source_index}.wav", normalize=False)

        # Loudspeakers to microphones ("H" matrix):
        for ls_index in range(num_ls):
            loudspeaker = loudspeakers[room_index][ls_index]

            spatial_ir = results[room_index].get_spatial_ir(source=loudspeaker, receiver=microphone)
            device_ir = spatial_ir.render_device_ir(device=device_model,
                                                    orientation=treble.Rotation(azimuth=float(mic_rotations[room_index][mic_index][0]),
                                                                                elevation=float(mic_rotations[room_index][mic_index][1])))
            device_ir.write_to_wav(path_to_file=f"Audio Data/Physical RIRs/Room {room_index + 1}/H_R{mic_index}_S{ls_index}.wav", normalize=False)

#%% Full Simulation: save other .wav files ("E" src to rec, "F" ls to rec)
for room_index in range(num_rooms):
    for receiver_index in range(num_receivers):
        receiver = receivers[room_index][receiver_index]
        # "E" src to rec:
        for source_index in range(num_sources):
            source = sources[room_index][source_index]
            ir = results[room_index].get_mono_ir(source=source, receiver=receiver)
            ir.write_to_wav(path_to_file=f"Audio Data/Physical RIRs/Room {room_index + 1}/E_R{receiver_index}_S{source_index}.wav", normalize=False)

        # "F" ls to rec:
        for ls_index in range(num_ls):
            loudspeaker = loudspeakers[room_index][ls_index]
            ir = results[room_index].get_mono_ir(source=loudspeaker, receiver=receiver)
            ir.write_to_wav(path_to_file=f"Audio Data/Physical RIRs/Room {room_index + 1}/F_R{receiver_index}_S{ls_index}.wav", normalize=False)

#%% Plot results/acoustic params
results[0].plot()
# results[0].get_acoustic_parameters("source_1", "receiver_1").plot()

#%% Save wav
results[0].get_mono_ir("source_1", "receiver_1").write_to_wav(path_to_file="room_2.wav", normalize=False)