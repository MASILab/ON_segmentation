function [cropped_fname,sz,crop_min,crop_max] = crop_ON_MR_v2(img_fname,centroids,varargin)
%CROP_ON_MR_V2 - Crop an input image based on the eye localizer and a
%threshold
%
% Syntax:  cropped_fname = crop_ON_MR_v2(img_fname,eye_prob,thresh,[out_dir])
%
% Inputs:
%    img_fname - The input image to be cropped
%    centroids - the centroids of the eyes in row,col,slice coordinates
%    out_dir - if omitted, saved in a temp directory
%
% Outputs:
%    cropped_fname - Filename of the cropped image
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: localize_ON_MR_v2
%
% Author:  harrigr
% Date:    27-Nov-2015 13:08:39
% Version: 1.0
% Changelog:
%
% 27-Nov-2015 13:08:39 - initial creation
%
%------------- BEGIN CODE --------------
narginchk(2,3);
if nargin==2
    out_dir = tempdir;
else
    out_dir = varargin{1};
end


nii_img = load_untouch_nii_gz(img_fname);
img = nii_img.img;

%We could check the areas here but that would differ based on the image
%resolution...
pixdim = nii_img.hdr.dime.pixdim(2:4);
sz = nii_img.hdr.dime.dim(2:4);

%assume axial
LR_dim = 1;
AP_dim = 2;
SI_dim = 3;

%Pad for 5mm in LR and SI and 20mm in AP
padLR = 30; %mm
padSI = 40;
eye_pad = 60; %mm
crop_min = min(centroids,[],1);
crop_max = max(centroids,[],1);
crop_min(LR_dim) = crop_min(LR_dim) - (padLR/pixdim(LR_dim));
crop_min(SI_dim) = crop_min(SI_dim) - (padSI/pixdim(SI_dim));
crop_max(LR_dim) = crop_max(LR_dim) + (padLR/pixdim(LR_dim));
crop_max(SI_dim) = crop_max(SI_dim) + (padSI/pixdim(SI_dim));
%Figure out which side the eyes are on and go backwards
if      (centroids(1,AP_dim) - sz(AP_dim)/2) > 0 && ...
        (centroids(2,AP_dim) - sz(AP_dim)/2) > 0
    %Eyes are gt the midline, we need to go negative
    crop_min(AP_dim) = crop_min(AP_dim) - (eye_pad/pixdim(AP_dim));
    crop_max(AP_dim) = crop_max(AP_dim) + (padLR/pixdim(AP_dim));
elseif  (centroids(1,AP_dim) - sz(AP_dim)/2) < 0 && ...
        (centroids(2,AP_dim) - sz(AP_dim)/2) < 0
    %Eyes are lt the midline, we need to go positive
    crop_max(AP_dim) = crop_max(AP_dim) + (eye_pad/pixdim(AP_dim));
    crop_min(AP_dim) = crop_min(AP_dim) - (padLR/pixdim(AP_dim));
else
    error('Could not localize the eye direction');
end

%Check image boundaries
crop_min = round(crop_min);
crop_max = round(crop_max);
crop_min(crop_min<1) = 1;
crop_max(crop_max>sz) = sz(crop_max>sz);


%FINALLY: crop the image
[X,Y,Z] = meshgrid(crop_min(2):crop_max(2),...
                   crop_min(1):crop_max(1),...
                   crop_min(3):crop_max(3));
indices = sub2ind(sz,Y,X,Z);
cropped_img = img(indices);
% slice_slider(double(cropped_img));
% figure;imagesc(cropped_img(:,:,round(size(cropped_img,3)/2)));axis image;

%Save out the result
cropped_fname = [out_dir,filesep, get_file_name(img_fname), '.nii.gz'];
cropped_nii = nii_img;
cropped_nii.img = cropped_img;
cropped_nii.hdr.dime.dim(2:4) = crop_max - crop_min + 1;
% cropped_nii.hdr.dime.dim(2) = crop_max(1)-crop_min(1)+1;
% cropped_nii.hdr.dime.dim(3) = crop_max(2)-crop_min(2)+1;
% cropped_nii.hdr.dime.dim(4) = crop_max(3)-crop_min(3)+1;

save_untouch_nii_gz(cropped_nii,cropped_fname);

%------------- END OF CODE --------------
