from treble_tsdk.tsdk import TSDK
from treble_tsdk import display_data as dd
from treble_tsdk import treble
import numpy as np
import matplotlib.pyplot as plt

tsdk = TSDK()

#%% Update absorption coefficients
# full-octave band definitions
f_axis_oct = np.asarray([63, 125, 250, 500, 1000, 2000, 4000, 8000])

# Absorption coefficients (surface_index (floor, ceiling, front wall, other walls), octave_band)
absorption_coefficients = np.asarray([[	0.2288,	0.1352,	0.16,	0.1659,	0.1892,	0.198,	0.2247,	0.1819	],

[	0.2948,	0.1742,	0.22,	0.1974,	0.1694,	0.086,	0.0903,	0.0731	],

[	0.1936,	0.1144,	0.085,	0.1323,	0.1254,	0.156,	0.2016,	0.1632	],

[	0.352,	0.208,	0.15,	0.2394,	0.2244,	0.28,	0.3612,	0.2924	]
									])

scattering_coefficients = [0.5, 0.15, 0.4, 0.3]

# Clamp coefficients
absorption_coefficients = absorption_coefficients.clip(0.0, 0.95)

#%% Create and fit all surface materials
room_num_label = 1

fitted_materials = []
material_names = [f"room_{room_num_label}_floor",
                  f"room_{room_num_label}_ceiling",
                  f"room_{room_num_label}_front_wall",
                  f"room_{room_num_label}_non_frontal_wall"]

for mat_index in range(4):
    # Create the material definition object
    material_definition = treble.MaterialDefinition(
        name=material_names[mat_index],
        description="Imported material",
        category=treble.MaterialCategory.other,
        default_scattering=scattering_coefficients[mat_index],
        material_type=treble.MaterialRequestType.full_octave_absorption,
        coefficients=absorption_coefficients[mat_index],
    )

    # Material fitting, nothing is saved in this step
    fitted_materials.append(tsdk.material_library.perform_material_fitting(material_definition))

#%% Visualise the fitting results
mat_index_to_plot = 0

# Retrieve the absorption coefficients from the fitted material
fitted_material_abs = fitted_materials[mat_index_to_plot].absorption_coefficients

plt.semilogx(f_axis_oct, absorption_coefficients[mat_index_to_plot], label='Original Coefficients')
plt.semilogx(f_axis_oct, fitted_material_abs, label='Fitted Coefficients')
plt.grid(which='both')
plt.xlim([50, 10000])
plt.ylim([0,1])
plt.xlabel('Frequency, Hz')
plt.ylabel('Absorption Coefficient')
plt.title('Input vs. Fitted Absorption Coefficients')
plt.legend()
plt.show()

#%% Delete existing materials
for mat_index in range(4):
    material = tsdk.material_library.search(material_names[mat_index])[0]
    tsdk.material_library.delete(material)

#%% Save materials
for mat_index in range(4):
    current_material = tsdk.material_library.create(fitted_materials[mat_index])
    dd.as_tree(current_material)