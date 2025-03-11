% This script generates RIRs using AKtools for a set of rooms with varying
% dimensions and absorption coefficients. A fully-factorial combination of
% the params will be generated, where the arguments are stored in seperate
% files e.g. "Room Dimensions/room_dimensions_1.dat"

% ******** ASSUMPTIONS ********
% The transducer coordinates, rotations and directivities will be paired
% with the room dims i.e. room dims 1 will always be rendered with
% transducer coords 1 etc.

% close all

%% User Parameters

% General audio parameters
sample_rate = 48000;
bit_depth = 32;

% This will read room_dimensions_1.dat to room_dimensions_[num_room_dims].dat
num_room_dims = 2; % 3
num_absorptions = 3;

room_dims_dir = "Simulation Parameters/Room Dimensions/";
absorptions_dir = "Simulation Parameters/Absorption Coefficients/";
coords_dir = "Simulation Parameters/Transducer Coordinates/";
rotations_dir = "Simulation Parameters/Transducer Rotations/";
directivities_dir = "Simulation Parameters/Transducer Directivities/";
output_dir = "Audio Data/Physical RIRs/";

% Permute all conditions
conditions = zeros(num_room_dims * num_absorptions, 2);

row = 1;
for room_dims_index = 1:num_room_dims
    for absorption_index = 1:num_absorptions
        conditions(row, 1) = room_dims_index;
        conditions(row, 2) = absorption_index;

        row = row + 1;
    end
end

% Generate RIRs for permutations
parfor row = 1:size(conditions, 1)
    room_dims_index = conditions(row, 1);
    absorption_index = conditions(row, 2);

    GenerateRIRs(room_dims_index, ...
        absorption_index, ...
        room_dims_dir, ...
        absorptions_dir, ...
        coords_dir, ...
        rotations_dir, ...
        directivities_dir, ...
        output_dir, ...
        sample_rate, ...
        bit_depth);
end

function GenerateRIRs(room_dims_index, absorptions_index, room_dims_dir, absorptions_dir, coords_dir, rotations_dir, directivities_dir, output_dir, sample_rate, bit_depth)
    room_dims = readmatrix(room_dims_dir + "room_dimensions_"+room_dims_index+".dat");
    alphas = readmatrix(absorptions_dir + "absorption_coeffs_"+absorptions_index+".dat");
    
    src_coords = readmatrix(coords_dir + "src_coords_"+room_dims_index+".dat");
    rec_coords = readmatrix(coords_dir + "rec_coords_"+room_dims_index+".dat");
    ls_coords = readmatrix(coords_dir + "ls_coords_"+room_dims_index+".dat");
    mic_coords = readmatrix(coords_dir + "mic_coords_"+room_dims_index+".dat");
    
    src_rotations = readmatrix(rotations_dir + "src_rotations.dat");
    rec_rotations = readmatrix(rotations_dir + "rec_rotations.dat");
    ls_rotations = readmatrix(rotations_dir + "ls_rotations_"+room_dims_index+".dat");
    mic_rotations = readmatrix(rotations_dir + "mic_rotations_"+room_dims_index+".dat");
    
    src_directivities = string(readcell(directivities_dir + "src_directivities.csv"));
    rec_directivities = string(readcell(directivities_dir + "rec_directivities_3rd_order.csv"));
    ls_directivities = string(readcell(directivities_dir + "ls_directivities_"+room_dims_index+".csv"));
    mic_directivities = string(readcell(directivities_dir + "mic_directivities_"+room_dims_index+".csv"));
    
    current_config = RoomWithAAES(room_dims, ...
        alphas, ...
        src_coords, ...
        rec_coords, ...
        ls_coords, ...
        mic_coords, ...
        src_rotations, ...
        rec_rotations, ...
        ls_rotations, ...
        mic_rotations, ...
        src_directivities, ...
        rec_directivities, ...
        ls_directivities, ...
        mic_directivities, ...
        sample_rate, ...
        bit_depth);
    current_config.GenerateSystemIRs(output_dir + "Room "+room_dims_index+" Absorption "+absorptions_index+"/", true, true);
end