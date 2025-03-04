% This script finds the one-to-one mapping of an AAES routing matrix (from
% microphones to loudspeakers) that exhibits the maximum overall system
% delay. The aim of this is to find the AAES routing that should result
% in the least risk in terms of colouration due to strong direct paths

% ============== INPUTS ==============
% loudspeaker_to_mic_matrix_irs = a square matrix of IRs characterising the
% loudspeaker-to-microphone path in some AAES

% ============== OUTPUTS ==============
% routing = a permutation matrix defining the optimal routing relative to
% loudspeaker_to_mic_matrix_irs

fs = 48000;
search_for_max_length = 100000;
H = zeros(16, 16, search_for_max_length);
H = FillIRMatrix(H, search_for_max_length, "H", "Simulated Physical RIRs/Room 1 Absorption 1/");

FindRouting(H, fs, false)

function permutations = FindRouting(loudspeaker_to_mic_matrix_irs, fs, return_first_max_only)
    num_chans = size(loudspeaker_to_mic_matrix_irs, 1);
    delays = zeros(num_chans);
    
    % Find all zero-to-max(abs) delays in samples
    for row = 1:num_chans
        for col = 1:num_chans
            b = abs(loudspeaker_to_mic_matrix_irs(row, col, :));
            [~, delays(row, col)] = max(abs(loudspeaker_to_mic_matrix_irs(row, col, :)));
        end
    end

    % Sort columns into longest (1, :) to shortest (end, :)
    [delays_sorted, sorted_row_positions] = sort(delays,"descend");

    % Check indices of first row (if all are different, this is optimal)
    % Iterate through each col of the first row, checking if the index
    % matches any elements of the output routing, which is written to after
    % each col iteration. If if matches, a duplicate is found, so increment
    % the row and check again. make sure this is reset for the next column.
    all_permutations = zeros(num_chans);

    for start = 0:num_chans-1
        for col = mod(start:num_chans-1 + start, num_chans) + 1
            row = 1;
    
            while (any(sorted_row_positions(row, col) == all_permutations(start+1, :)))
                row = row + 1;
            end
    
            all_permutations(start+1, col) = sorted_row_positions(row, col);
        end
    end

    % Evaluate total delay of each row
    permuted_delays = delays_sorted(all_permutations);
    total_delays = sum(permuted_delays, 2);
    max_total_row_delay = max(total_delays);

    % Return one or all rows of permutations resulting in the max delay
    if return_first_max_only
        max_row = find(total_delays == max_total_row_delay, 1);
    else
        max_row = total_delays == max_total_row_delay;
    end

    disp("Min delay in dataset: " + (min(delays_sorted(num_chans,:)) / fs) * 1000 + " ms");
    disp("Max delay in dataset: " + (max(delays_sorted(1,:)) / fs) * 1000 + " ms");
    disp("Min selected delay: " + (min(permuted_delays(1,:)) / fs) * 1000 + " ms");
    disp("Max selected delay: " + (max(permuted_delays(1,:)) / fs) * 1000 + " ms");
    disp("Total selected delay: " + (max_total_row_delay / fs) * 1000 + " ms");
    permutations = all_permutations(max_row,:);
end

function matrix_to_fill = FillIRMatrix(matrix_to_fill, desired_ir_length, filename_base_id, ir_directory)
    num_rows = size(matrix_to_fill,1);
    num_cols = size(matrix_to_fill,2);

    % Load each IR and insert into IR matrix
    for row = 1:num_rows
        for col = 1:num_cols
            padded_ir = zeros(desired_ir_length, 1);
    
            [raw_ir, ~] = audioread(ir_directory + filename_base_id + "_R" + row + "_S" + col + ".wav");
        
            nonzero_length = min(length(raw_ir), desired_ir_length); % Iterate up to the end of the audio, truncating if too long

            padded_ir(1:nonzero_length) = raw_ir(1:nonzero_length);
            matrix_to_fill(row, col, :) = padded_ir;
        end
    end
end