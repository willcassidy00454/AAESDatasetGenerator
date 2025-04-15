import random

from treble_tsdk.tsdk import TSDK
from treble_tsdk import display_data as dd
from treble_tsdk import treble

tsdk = TSDK()

#%%
# Check what projects were created by your credentials
projects = tsdk.list_my_projects()
dd.display(projects)

#%%
# create a project with a given name, and check that it has been added to your list of projects
# tsdk.create_project("SimulationTest")

#%%
# retrieve the project by name: if you have previously create the project My Unique Project Name, you can skip directly to get_by_name.
project = tsdk.get_by_name("SimulationTest")

#%%
# Create a shoebox room
room = treble.GeometryDefinitionGenerator.create_shoebox_room(
    width_x=3,
    depth_y=6,
    height_z=2,
    join_wall_layers=True,
)

# get furniture components
sofa = tsdk.geometry_component_library.query(group="sofa")[1]
chair = tsdk.geometry_component_library.query(group="chair")[1]
table = tsdk.geometry_component_library.query(group="table")[0]

# define positions for the furniture and add the objects to the room
sofa_pos = treble.Vector3d(1.5, 5.5, 0)
room.add_geometry_component("my_comfy_sofa", sofa, treble.Transform3d(sofa_pos, treble.Rotation(0, 0, 0)))

chair1_pos = sofa_pos + treble.Vector3d(-1, -3.2, 0)
chair2_pos = sofa_pos + treble.Vector3d(0, -3.5, 0)
chair3_pos = sofa_pos + treble.Vector3d(0, -2.7, 0)

room.add_geometry_component("my_chair1", chair, treble.Transform3d(chair1_pos, treble.Rotation(-135, 0, 0)))
room.add_geometry_component("my_chair2", chair, treble.Transform3d(chair2_pos, treble.Rotation(-90, 0, 0)))
room.add_geometry_component("my_chair3", chair, treble.Transform3d(chair3_pos, treble.Rotation(60, 0, 0)))

table_pos = treble.Vector3d(1, 4, 0)
room.add_geometry_component("my_table", table, treble.Transform3d(table_pos, treble.Rotation(0, 0, 0)))

# plot the room
room.plot()

# add the room to the project
# model = project.add_model("RoomTest", room)
model = project.get_model_by_name("RoomTest")

#check that the model has been added to the project
dd.display(project.get_models())

#%%
# Get a list with all materials associated with the organization
all_materials = tsdk.material_library.get()

# Remove materials that are user-generated
database_materials = [material for material in all_materials if material["organizationId"] == None]

# first check what the layer names are
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

# create an empty material assignment before the loop
material_assignment = []

# grab a random material from the default materials that comes closer to a realistic assignment
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

# show the material assignment
dd.display(material_assignment)

#%%
receivers = [treble.Receiver.make_spatial(
                position=treble.Point3d(x=1.5, y=4, z=1.5),
                label="Spatial_receiver",
                ambisonics_order=4)]

sources = [treble.Source.make_omni(position=treble.Point3d(1.5,0.5,1.5),
                                   label="source_1")]

#%%
sim_def = treble.SimulationDefinition(
        name="Simulation_5", # unique name of the simulation
        simulation_type=treble.SimulationType.ga, # the type of simulation
        model=model, # the model we created in an earlier step
        energy_decay_threshold=40, # simulation termination criteria - the simulation stops running after -40 dB of energy decay
        receiver_list=receivers,
        source_list=sources,
        material_assignment=material_assignment
)

# double check that all the receivers and sources fall within the room
sim_def.remove_invalid_receivers()
sim_def.remove_invalid_sources()

# plot the simulation before adding it to the project
sim_def.plot()

# create a simulation from the definition
simulation = project.add_simulation(sim_def)

#%%
simulation.start()
simulation.as_live_progress()

#%%
dd.display(simulation.get_tasks())

#%%
results_object = simulation.download_results(f'results/{simulation.name}')
# results_object = simulation.get_results_object("results/Simulation_3")

#%%
# begin to explore the results
results_object.plot()

# isolate the data from a single impulse response
# spatial_ir = results_object.get_spatial_ir(source=simulation.sources[0],receiver=simulation.receivers[0])
#
# spatial_ir.write_to_wav(path_to_file="spatial_ir.wav")

# time is just a 1d vector here, since it's the same for all channels
# data is num_channels x num_samples
# plt.plot(spatial_ir.time, spatial_ir.data[0])
# plt.plot(spatial_ir.time, spatial_ir.data[1])
# plt.plot(spatial_ir.time, spatial_ir.data[2])
# plt.show()