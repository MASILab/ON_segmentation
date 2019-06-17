function make_dir_if_doesnt_exist(dir_path)
%MAKE_DIR_IF_DOESNT_EXIST - makes a directory if it doesn't exist
% Syntax:  make_dir_if_doesnt_exist(dir_path)
%
% Inputs:
%    dir_path - directory to make
%
%
% Example: 
%    make_dir_if_doesnt_exist('/tmp/test_segmentation');
%
% See also: mkdir,  exist
%
% Author:  plassaaj
% Date:    12-Feb-2015 13:52:51
% Version: 1.0
% Changelog:
%
% 12-Feb-2015 13:52:51 - initial creation
%
%------------- BEGIN CODE --------------

if ~exist(dir_path,'dir')
    mkdir(dir_path)
end

%------------- END OF CODE --------------