function names = get_file_name(fnames)
%GET_FILE_NAME - utility to get a file name from a fully qualified path
% Useful instead of fileparts when dealing with multiple extensions (ie
% .nii.gz)
%
% Syntax:  name = get_file_name(fnames)
%
% Inputs:
%    fname - Fully qualified filename
%
% Outputs:
%    name - The name of the file with all extensions and the path
%    removed, or cell string of multiple filenames
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: OTHER_FUNCTION_NAME1,  OTHER_FUNCTION_NAME2
%
% Author:  harrigr
% Date:    19-Nov-2015 09:54:37
% Version: 1.0
% Changelog:
%
% 19-Nov-2015 09:54:37 - initial creation
%
%------------- BEGIN CODE --------------

%Check if the input is a cell or just a string
if ~iscellstr(fnames)
    inputWasCellStr = false;
    fnames = {fnames};
else
    inputWasCellStr = true;
end

names = cell(size(fnames));
for i=1:numel(fnames)
    fname = fnames{i};
    %remove path
    fseps = strfind(fname,filesep);
    if isempty(fseps)
        %This handles the case that only a filename is passed in (no path)
        name_w_ext = fname;
    else
        name_w_ext = fname(fseps(end)+1:end);
    end
    
    %remove extensions
    dots = strfind(name_w_ext,'.');
    if isempty(dots)
        %No extension case
        name = name_w_ext;
    else
        name = name_w_ext(1:dots(1)-1);
    end
    names{i} = name;
end

%If the input was just a string, return just a string
if ~inputWasCellStr
    names = names{1};
end
%------------- END OF CODE --------------