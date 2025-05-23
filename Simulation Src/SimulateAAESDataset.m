
rir_base_dir = "Audio Data/Physical RIRs/";
reverberator_base_dir = "Audio Data/Reverberators/";
output_base_dir = "Audio Data/AAES Receiver RIRs/";
permutations_base_dir = "Simulation Parameters/Permutations/";
routings_base_dir = "Simulation Parameters/Routings/";

loop_gains = readmatrix("Simulation Parameters/Loop Gains/loop_gains.dat");

bit_depth = 32;

num_mics = 16;
num_ls = 16;

% Parameters to combine
num_rooms = 3;
num_absorptions = 3;
num_rt_ratios = 3;
num_filters = 3;
num_loop_gains = length(loop_gains);
num_routings = 4;

num_conditions_to_select = 112; % Selects a subset of the full dataset
random_condition_offset = 3; % Randomly selects neighbours of the uniformly
% sampled conditions by up to this value. Use this to avoid missing an
% argument entirely due to the regularity of uniform sampling.

% Make matrix of combinations where each row defines each simulation
% Columns: room index, absorptions index, reverberator index, loop gain (dB
% from GBI)
all_conditions = zeros(num_loop_gains * num_rooms * num_absorptions * num_rt_ratios * num_filters * num_routings, 6);

row = 1;
for loop_gain_index = 1:num_loop_gains
    for rt_ratio_index = 1:num_rt_ratios
        for absorption_index = 1:num_absorptions
            for room_index = 1:num_rooms
                for routing_index = 1:num_routings
                    for filter_index = 1:num_filters
                        all_conditions(row, 1) = room_index;
                        all_conditions(row, 2) = absorption_index;
                        all_conditions(row, 3) = rt_ratio_index;
                        all_conditions(row, 4) = filter_index;
                        all_conditions(row, 5) = loop_gain_index;
                        all_conditions(row, 6) = routing_index;
        
                        row = row + 1;
                    end
                end
            end
        end
    end
end

reduced_conditions = zeros(num_conditions_to_select, size(all_conditions, 2));
step = floor(size(all_conditions, 1) / num_conditions_to_select);

for condition_index = 1:num_conditions_to_select
    stepped_condition_index = (condition_index * step) + randi(random_condition_offset);
    % % % add catch for when the rand pushed out of bounds
    reduced_conditions(condition_index,:) = all_conditions(stepped_condition_index, :);
end

% Simulate each row in the conditions matrix
parfor row = 1:size(reduced_conditions, 1)
    room_index = reduced_conditions(row, 1);
    absorption_index = reduced_conditions(row, 2);
    rt_ratio_index = reduced_conditions(row, 3);
    filter_index = reduced_conditions(row, 4);
    loop_gain_index = reduced_conditions(row, 5);
    routing_index = reduced_conditions(row, 6);

    routing = readmatrix(routings_base_dir + "routing_" + routing_index + "_room_" + room_index + ".dat");

    GenerateAAESIRs(rir_base_dir + "Room "+room_index+" Absorption "+absorption_index+"/", ...
        reverberator_base_dir + "Reverberator Room "+room_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Filter "+filter_index+"/", ...
        output_base_dir + "AAES Room "+room_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Loop Gain "+loop_gain_index+" Filter "+filter_index+" Routing "+routing_index+"/", ...
        loop_gains(loop_gain_index), ...
        num_ls, ...
        num_mics, ...
        bit_depth, ...
        true, ...
        true, ...
        true, ...
        routing);
end