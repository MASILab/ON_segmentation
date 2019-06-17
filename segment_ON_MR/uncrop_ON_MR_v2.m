function result = uncrop_ON_MR_v2(img_fname,sz,crop_min,crop_max)
%UNCROP_ON_MR_V2 - Undo the cropping done by crop_ON_MR_v2 after
%segmentation
%
% Syntax:  result = uncrop_ON_MR_v2(img_fnmae,sz,crop_min,crop_max)
%
% Inputs:
%    img_fname - Description
%    sz        - Description
%    crop_min  - Description
%    crop_max  - Description
%
% Outputs:
%    result - 
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: crop_ON_MR_v2
%
% Author:  harrigr
% Date:    27-Nov-2015 13:09:15
% Version: 1.0
% Changelog:
%
% 27-Nov-2015 13:09:15 - initial creation
%
%------------- BEGIN CODE --------------

%Load in the cropped labels
nii_img = load_untouch_nii_gz(img_fname);
if isequal(nii_img.hdr.dime.dim(2:4), sz)
    %image is already uncropped
    result=0;
    return;
end

cropped_img = nii_img.img;

%Create an empty image the right size
full_img = zeros(sz);
[X,Y,Z] = meshgrid(crop_min(2):crop_max(2),...
                   crop_min(1):crop_max(1),...
                   crop_min(3):crop_max(3));
indices = sub2ind(sz,Y,X,Z);
%Fill in the data from the cropped image
full_img(indices) = cropped_img(:);
% full_img = reshape(full_img,sz); %unnecessary

%Save back out with the right size image
full_nii = nii_img;
full_nii.hdr.dime.dim(2:4) = sz;
full_nii.img = full_img;

save_untouch_nii_gz(full_nii,img_fname);
result=0;

%------------- END OF CODE --------------