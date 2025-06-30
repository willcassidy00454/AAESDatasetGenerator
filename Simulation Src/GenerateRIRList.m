% Writes a list of indices relating to the simulation parameters, namely
% room_size, absorption, rt_ratio, filter, loop_gain, and routing, to be
% loaded by SimulateAAESDataset.m for simulation. An initial set of indices
% are loaded, and extra combinations are generated, skipping duplicates,
% and appended to the existing index list.

% Output file
box_behnken_list_dir = "Simulation Parameters/RIR List/box_behnken_list.dat";
stimulus_list_write_dir = "Simulation Parameters/RIR List/rir_list.dat";

total_num_rirs = 110; % Generating 9 less than 119 as there are 9 passive rooms
num_parameters = 6;

% Columns: room_size, absorption, rt_ratio, filter, loop_gain, routing
all_conditions = zeros(total_num_rirs, num_parameters);

% Add Box-Behnken design indices to list of all conditions
box_behnken_variations = readmatrix(box_behnken_list_dir);

all_conditions(1:length(box_behnken_variations), :) = box_behnken_variations;

% Fill the remaining rows with randomised variations, skipping duplicates
rng("default") % Set seed
num_random_variations = total_num_rirs - length(box_behnken_variations);

unique_count = 0;

while unique_count < num_random_variations
    randomised_variations_row = [randi(3), randi(3), randi(3), randi(3), randi(3), randi(3)];

    if ~ismember(randomised_variations_row, all_conditions, "rows")
        all_conditions(length(box_behnken_variations) + unique_count + 1, :) = randomised_variations_row;
        unique_count = unique_count + 1;
    end
end

% Write to file
writematrix(all_conditions, stimulus_list_write_dir);

