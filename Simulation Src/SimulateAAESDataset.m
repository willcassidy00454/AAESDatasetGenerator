
rir_base_dir = "Audio Data/Physical RIRs/";
reverberator_base_dir = "Audio Data/Reverberators/";
output_base_dir = "Audio Data/AAES Receiver RIRs/";
permutations_base_dir = "Simulation Parameters/Permutations/";
routings_base_dir = "Simulation Parameters/Routings/";
stimulus_list_dir = "Simulation Parameters/RIR List/rir_list.dat";

loop_gains = readmatrix("Simulation Parameters/Loop Gains/loop_gains.dat");

bit_depth = 32;

num_mics = 16;
num_ls = 16;

all_conditions = readmatrix(stimulus_list_dir);

% Simulate each row in the conditions matrix
for row = 1:size(all_conditions, 1)
    room_index = all_conditions(row, 1);
    absorption_index = all_conditions(row, 2);
    rt_ratio_index = all_conditions(row, 3);
    filter_index = all_conditions(row, 4);
    loop_gain_index = all_conditions(row, 5);
    routing_index = all_conditions(row, 6);

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