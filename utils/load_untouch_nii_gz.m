function nii = load_untouch_nii_gz2(filenameIN, varargin)
% LOAD_UNTOUCH_NII_GZ - Loads a *.nii.gz file in matlab.
%
% There are two different forms of this function:
%
% 1 - nii = load_untouch_nii_gz(filenameIN)
% 2 - nii = load_untouch_nii_gz(filenameIN, filesuffix)
%
% Input: filenameIN - the .nii.gz file to load
%        filesuffix (opt) - an explicit filename suffix to add to the
%                           temporary file that is saved. This may be necessary
%                           if loading multiple files simultaneously as the
%                           default suffix is a pseudo-random number.
%
% Output: nii - The nifti struct.

filename = [tempname '.nii'];

% unzip to the temporary filename
% system(sprintf('gzip -dc %s > %s',filenameIN,filename));
if ispc
    orig_filename = gunzip(filenameIN,tempdir);
    movefile(orig_filename{1},filename);
else
    system(sprintf('gzip -dc %s > %s',filenameIN,filename));
end
% try to load the nifti file
nii = load_untouch_nii(filename);

% delete the temporary file
delete(filename);
