from treble_tsdk import display_data as dd
import numpy as np
from treble_tsdk.tsdk import TSDK, TSDKCredentials
from treble_tsdk import treble
import matplotlib.pyplot as plt

# tsdk = TSDK(TSDKCredentials.sso(...)) include your credentials here

#%% Update absorption coefficients
# full-octave band definitions
f_axis_oct = np.asarray([63, 125, 250, 500, 1000, 2000, 4000, 8000])

# Absorption coefficients (surface_index (floor, ceiling, front wall, other walls), octave_band)
absorption_coefficients = np.asarray([[	0.285,	0.2475,	0.375,	0.3,	0.3,	0.33,	0.33,	0.3	],

[	0.285,	0.2475,	0.375,	0.3,	0.3,	0.33,	0.33,	0.3	],

[	0.285,	0.2475,	0.375,	0.3,	0.3,	0.33,	0.33,	0.3	],

[	0.285,	0.2475,	0.375,	0.3,	0.3,	0.33,	0.33,	0.3	]

									])

scattering_coefficients = [0.5, 0.15, 0.4, 0.3]

# Clamp coefficients
absorption_coefficients = absorption_coefficients.clip(0.01, 0.95)

#%% Create and fit all surface materials
absorption_index = 1 # Starts at 0

fitted_materials = []
material_names = [f"absorption_{absorption_index + 1}_floor",
                  f"absorption_{absorption_index + 1}_ceiling",
                  f"absorption_{absorption_index + 1}_front_wall",
                  f"absorption_{absorption_index + 1}_non_frontal_wall"]

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
fitted_material_coeffs = fitted_materials[mat_index_to_plot].absorption_coefficients

plt.semilogx(f_axis_oct, absorption_coefficients[mat_index_to_plot], label='Original Coefficients')
plt.semilogx(f_axis_oct, fitted_material_coeffs, label='Fitted Coefficients')
plt.grid(which='both')
plt.xlim([50, 10000])
plt.ylim([0,1])
plt.xlabel('Frequency, Hz')
plt.ylabel('Absorption Coefficient')
plt.title('Input vs. Fitted Absorption Coefficients')
plt.legend()
plt.show()

#%% Replace materials
for mat_index in range(4):
    material = tsdk.material_library.get_by_name(material_names[mat_index])
    tsdk.material_library.delete(material)

    current_material = tsdk.material_library.create(fitted_materials[mat_index])
    dd.as_tree(current_material)