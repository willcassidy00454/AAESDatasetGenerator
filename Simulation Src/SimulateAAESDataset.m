
rir_base_dir = "Audio Data/Physical RIRs/";
reverberator_base_dir = "Audio Data/Reverberators/";
output_base_dir = "Audio Data/AAES Receiver RIRs/";

loop_gains = readmatrix("Simulation Parameters/Loop Gains/LoopGains.dat");

bit_depth = 32;

num_mics = 16;
num_ls = 16;

% Parameters to combine
num_loop_gains = length(loop_gains);
num_rooms = 3;
num_absorptions = 3;
num_reverberators = 4;

% Make matrix of combinations where each row defines each simulation
% Columns: room index, absorptions index, reverberator index, loop gain (dB
% from GBI)
conditions = zeros(num_loop_gains * num_rooms * num_absorptions * num_reverberators, 4);

row = 1;
for loop_gain_index = 1:num_loop_gains
    for reverberator_index = 1:num_reverberators
        for absorptions_index = 1:num_absorptions
            for room_index = 1:num_rooms
                conditions(row, 1) = room_index;
                conditions(row, 2) = absorptions_index;
                conditions(row, 3) = reverberator_index;
                conditions(row, 4) = loop_gains(loop_gain_index);

                row = row + 1;
            end
        end
    end
end

% Simulate each row in the conditions matrix
for row = 1:size(conditions, 1)
    room_index = conditions(row, 1);
    absorptions_index = conditions(row, 2);
    reverberator_index = conditions(row, 3);
    loop_gain = conditions(row, 4);

    GenerateAAESIRs(rir_base_dir + "Room "+room_index+" Absorption "+absorptions_index+"/", ...
        reverberator_base_dir + "Reverberator "+reverberator_index+"/", ...
        output_base_dir + "AAES Room "+room_index+" Abs "+absorptions_index+" Rev "+reverberator_index+" LG "+loop_gain+"/", ...
        loop_gain, ...
        num_ls, ...
        num_mics, ...
        bit_depth, ...
        true, ...
        true);
end