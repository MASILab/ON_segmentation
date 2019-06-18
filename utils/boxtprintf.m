function boxtprintf(varargin)
%BOXTPRINTF - same as tprintf except surrounds text in a line above and
%below, adds newline character after input
%
% boxtprintf(varargin)
% 
% Input: typical printf format
% Output: none
%
% Author:  harrigr
% Date:    18-Nov-2015 12:47:25
% Version: 1.0
% Changelog:
%
% 18-Nov-2015 12:47:25 - initial creation
%
%------------- BEGIN CODE --------------

try
    et = toc;
catch err
    fprintf(varargin{:});
    return;
end

hrs = floor(et / 3600);
et = rem(et, 3600);
mins = floor(et / 60);
secs = round(rem(et, 60));
fprintf('[%02dh %02dm %02ds]\n', hrs, mins, secs);
fprintf('[%02dh %02dm %02ds] %s\n', hrs, mins, secs, repmat('-',[1 80]));
fprintf('[%02dh %02dm %02ds] %s\n', hrs, mins, secs, sprintf(varargin{:}));
fprintf('[%02dh %02dm %02ds] %s\n', hrs, mins, secs, repmat('-',[1 80]));
fprintf('[%02dh %02dm %02ds]\n', hrs, mins, secs);

%------------- END OF CODE --------------