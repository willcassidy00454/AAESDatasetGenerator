
function PlotTransducers(coords_dir, rotations_dir, room_index)
    close all
    mic_coords = readmatrix(coords_dir + "mic_coords_" + room_index + ".dat");
    ls_coords = readmatrix(coords_dir + "ls_coords_" + room_index + ".dat");

    mic_rotations = readmatrix(rotations_dir + "mic_rotations_" + room_index + ".dat");
    ls_rotations = readmatrix(rotations_dir + "ls_rotations_" + room_index + ".dat");

    grid on
    hold on
    PlotPoints(mic_coords, mic_rotations, true);
    PlotPoints(ls_coords, ls_rotations, false);
    title("Room " + room_index, "FontSize", 16);
end

function PlotPoints(coords, rotations, is_mic)
    if is_mic
        marker = "o";
    else
        marker = "+";
    end
        
    scatter3(coords(:,1), coords(:,2), coords(:,3), "Marker", marker);
    xlim([0, max(coords(:,1)) + 2]);
    ylim([0, max(coords(:,2)) + 2]);
    zlim([0, max(coords(:,3)) + 1]);

    xlabel("x");
    ylabel("y");
    zlabel("z");

    num_chans = length(coords);
    text(coords(:,1) + 0.5, coords(:,2), coords(:,3), string(1:num_chans));
    text(coords(:,1), coords(:,2) - 0.5, coords(:,3), "(" + string(rotations(:,1)) + " " + string(rotations(:,2)) + ")");
end