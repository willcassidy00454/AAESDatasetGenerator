import random

from treble_tsdk.tsdk import TSDK
from treble_tsdk import display_data as dd
from treble_tsdk import treble
import numpy as np

tsdk = TSDK()

#%% Check what projects were created by your credentials
projects = tsdk.list_my_projects()
dd.display(projects)

#%% Create a project with a given name, and check that it has been added to your list of projects
tsdk.create_project("AmbiToLSValidation")

#%% Retrieve the project by name: if you have previously create the project My Unique Project Name, you can skip directly to get_by_name.
project = tsdk.get_by_name("AmbiToLSValidation")

#%% Create a shoebox room
room = treble.GeometryDefinitionGenerator.create_shoebox_room(
    width_x=3,
    depth_y=6,
    height_z=2,
    join_wall_layers=True,
)

# Plot the room
# room.plot()

#%% Add the room to the project and display project models
model = project.add_model("ValidationRoom", room)
# model = project.get_model_by_name("ValidationRoom")

dd.display(project.get_models())

#%% Material assignment

# Get a list with all materials associated with the organization
all_materials = tsdk.material_library.get()

# Remove materials that are user-generated
database_materials = [material for material in all_materials if material["organizationId"] == None]

# First check what the layer names are
for layer in model.layer_names:
    print(layer)

# Create a dictionary associating layer names with acceptable material names
layer_to_search = {
    "shoebox_walls": "gypsum", #any gypsum material is acceptable
    "shoebox_floor": "carpet", #any carpeting is acceptable
    "shoebox_ceiling": "gypsum",
    "Furniture/Couch C": "85", #grab a flat 85% absorption for the couch
    "Furniture/Dining table": "wood", # any wood or wooden furnitures is acceptable
    "Furniture/Chair A": "wood",
}

# Create an empty material assignment before the loop
material_assignment = []

# Grab a random material from the default materials that comes closer to a realistic assignment
for layer in model.layer_names:
    if layer in layer_to_search:
        search_string = layer_to_search[layer]
        matches = [
            m for m in database_materials
            if search_string.lower() in m.name.lower()
        ]
        if matches:
            material_assignment.append(
                treble.MaterialAssignment(layer, random.choice(matches))
            )

# Show the material assignment
dd.display(material_assignment)

#%% Define source and receiver points (three rings (0.5 m radius) of omni sources around a spatial receiver)
centre_point = treble.Point3d(x=1.5, y=3, z=1.0)

# Receiver points along the left of the stage by default (along positive x-axis)
# This requires a -90 degree yaw correction using SPARTA, or a +90 degree yaw correction using IEM
# The result should point towards the stage
receiver = [treble.Receiver.make_spatial(
                position=centre_point,
                label="spatial_receiver",
                ambisonics_order=4)]

source_angles_degrees = [x for x in range(0,360,45)]
radius_metres = 0.5
source_x_deltas = radius_metres * np.sin(np.deg2rad(source_angles_degrees))
source_y_deltas = radius_metres * np.cos(np.deg2rad(source_angles_degrees))

sources = []

# Circle in horizontal plane, fixed Z
for source_index in range(len(source_x_deltas)):
    sources.append(treble.Source.make_omni(position=treble.Point3d(centre_point.x - source_x_deltas[source_index],
                                                                   centre_point.y - source_y_deltas[source_index],
                                                                   centre_point.z),
                                           label=f"source_{source_index + 1}"))
# Circle in median plane, fixed X
for source_index in range(len(source_x_deltas)):
    sources.append(treble.Source.make_omni(position=treble.Point3d(centre_point.x,
                                                                   centre_point.y - source_y_deltas[source_index],
                                                                   centre_point.z + source_x_deltas[source_index]),
                                           label=f"source_{source_index + 9}"))
# # Circle in interaural plane, fixed Y
for source_index in range(len(source_x_deltas)):
    sources.append(treble.Source.make_omni(position=treble.Point3d(centre_point.x + source_y_deltas[source_index],
                                                                   centre_point.y,
                                                                   centre_point.z + source_x_deltas[source_index]),
                                           label=f"source_{source_index + 17}"))

#%% Make simulation definition
sim_def = treble.SimulationDefinition(
        name="AmbiToLSValidation", # unique name of the simulation
        simulation_type=treble.SimulationType.ga, # the type of simulation
        model=model, # the model we created in an earlier step
        energy_decay_threshold=30, # simulation termination criteria - the simulation stops running after -40 dB of energy decay
        receiver_list=receiver,
        source_list=sources,
        material_assignment=material_assignment
)

# Plot the simulation
sim_def.plot()

#%% Replace project simulation definition
project.delete_simulation(project.get_simulation_by_name("AmbiToLSValidation"))
simulation = project.add_simulation(sim_def)

#%% Run simulation
simulation.start()
# simulation.as_live_progress()

#%% Check progress
dd.display(simulation.get_tasks())

#%% Download results and save to .wavs
results = simulation.download_results(f'Validation Results/{simulation.name}')

for source_index in range(8):
    ir = results.get_spatial_ir(source=sources[source_index].label, receiver=receiver[0].label)
    ir.write_to_wav(
        path_to_file=f"Validation Results/Validation RIRs/horizontal_{source_index + 1}.wav")
    ir = results.get_spatial_ir(source=sources[source_index + 8].label, receiver=receiver[0].label)
    ir.write_to_wav(
        path_to_file=f"Validation Results/Validation RIRs/median_{source_index + 1}.wav")
    ir = results.get_spatial_ir(source=sources[source_index + 16].label, receiver=receiver[0].label)
    ir.write_to_wav(
        path_to_file=f"Validation Results/Validation RIRs/interaural_{source_index + 1}.wav")