function print_params(params)
% i hated typing this in several places, looked junky
if length(params) ==8
    fprintf(['\tParams:\n\t[sx: %.6f]\n\t[sy: %.6f]\n\t[r : %.6f]\n'...
        '\t[s2: %.6f]\n\t[i0: %.6f]\n\t[b : %.6f]\n'...
        '\t[ux: %.6f]\n\t[uy: %.6f]\n'],params(1),params(2),params(3), ...
        params(4),params(5),params(6),params(7),params(8));
elseif length(params) == 9
    fprintf(['\tParams:\n\t[sx: %.6f]\n\t[sy: %.6f]\n\t[r : %.6f]\n'...
        '\t[s1: %.6f]\n\t[s2: %.6f]\n\t[i0: %.6f]\n\t[b : %.6f]\n'...
        '\t[ux: %.6f]\n\t[uy: %.6f]\n'],params(1),params(2),params(3), ...
        params(4),params(5),params(6),params(7),params(8),params(9));
end
end