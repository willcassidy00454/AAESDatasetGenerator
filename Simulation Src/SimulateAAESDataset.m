
rir_base_dir = "Audio Data/Physical RIRs/";
reverberator_base_dir = "Audio Data/Reverberators/";
output_base_dir = "Audio Data/AAES Receiver RIRs/";
permutations_base_dir = "Simulation Parameters/Permutations/";
routings_base_dir = "Simulation Parameters/Routings/";

loop_gains = readmatrix("Simulation Parameters/Loop Gains/LoopGains.dat");

bit_depth = 32;

num_mics = 16;
num_ls = 16;

% Parameters to combine
num_loop_gains = length(loop_gains);
num_rooms = 3;
num_absorptions = 3;
num_rt_ratios = 3;
num_filters = 3;
num_routings = 4;

% Make matrix of combinations where each row defines each simulation
% Columns: room index, absorptions index, reverberator index, loop gain (dB
% from GBI)
conditions = zeros(num_loop_gains * num_rooms * num_absorptions * num_rt_ratios * num_filters * num_routings, 6);

row = 1;
for loop_gain_index = 1:num_loop_gains
    for rt_ratio_index = 1:num_rt_ratios
        for absorption_index = 1:num_absorptions
            for room_index = 1:num_rooms
                for routing_index = 1:num_routings
                    for filter_index = 1:num_filters
                        conditions(row, 1) = room_index;
                        conditions(row, 2) = absorption_index;
                        conditions(row, 3) = rt_ratio_index;
                        conditions(row, 4) = filter_index;
                        conditions(row, 5) = loop_gains(loop_gain_index);
                        conditions(row, 6) = routing_index;
        
                        row = row + 1;
                    end
                end
            end
        end
    end
end

% Simulate each row in the conditions matrix
for row = 1:size(conditions, 1)
    room_index = conditions(row, 1);
    absorption_index = conditions(row, 2);
    rt_ratio_index = conditions(row, 3);
    filter_index = conditions(row, 4);
    loop_gain = conditions(row, 5);
    routing_index = conditions(row, 6);

    % Load routing and multiply with permutation corresponding to this room
    raw_routing = readmatrix(routings_base_dir + "routing_" + routing_index + ".dat");
    permutation = readmatrix(permutations_base_dir + "room_" + room_index + ".dat");
    routing = raw_routing * permutation;

    GenerateAAESIRs(rir_base_dir + "Room "+room_index+" Absorption "+absorption_index+"/", ...
        reverberator_base_dir + "Reverberator Room "+room_index+" Absorption "+absorption_index+" RT "+rt_ratio_index+" Filter "+filter_index+"/", ...
        output_base_dir + "AAES Room "+room_index+" Absorption "+absorption_index+" Reverberator "+rt_ratio_index+" Loop Gain "+loop_gain+"/", ...
        loop_gain, ...
        num_ls, ...
        num_mics, ...
        bit_depth, ...
        true, ...
        true, ...
        true, ...
        routing);
end