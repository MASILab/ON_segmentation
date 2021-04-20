function eye_centroids = localize_ON_MR_affine(tgt_fname,output_dir,nr_path,atlas_images,atlas_labels,eye_label,thresh)
%LOCALIZE_ON_MR_AFFINE - Function to use affine registration to estimate
%the centroids of the left and right eyes
%
% Syntax:  eye_centroids = localize_ON_MR_affine(tgt_fname,atlas_images,atlas_labels,eye_labels)
%
% Inputs:
%    tgt_fname    - string filename of the target image, intermediate
%    results will be saved in this directory in a directory called
%    affine_reg
%    atlas_images - cell array of filenames for the atlas images
%    atlas_labels - cell array of filenames of the atlas labels
%    eye_label   - label value of the eye globes
%
% Outputs:
%    eye_centroids - The approximate centroids (in image coordinates) of
%                    the left and right eyes
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: OTHER_FUNCTION_NAME1,  OTHER_FUNCTION_NAME2
%
% Author:  harrigr
% Date:    11-Jan-2016 11:09:25
% Version: 1.0
% Changelog:
%
% 11-Jan-2016 11:09:25 - initial creation
%
%------------- BEGIN CODE --------------

%Intermediate directory to store results of registration
tgt_name = get_file_name(tgt_fname);
crop_dir = [output_dir,filesep,'targets'];
make_dir_if_doesnt_exist(crop_dir);
out_dir = [crop_dir,filesep,'affine_reg_',tgt_name];
make_dir_if_doesnt_exist(out_dir);

label_results = {};
tprintf('Registering %d atlases to %s\n',numel(atlas_images),tgt_name);
for i=1:numel(atlas_images)
    moving=atlas_images{i};
    moving_name = get_file_name(moving);
    tprintf('\tBeginning atlas %s\n',moving_name);
    label = atlas_labels{i};
    aff = [out_dir, filesep, 'aff_', moving_name, '.mat'];
    res = [out_dir, filesep, 'registered_', moving_name, '.nii.gz'];
    reslabs = [out_dir, filesep, 'label_', moving_name, '.nii.gz'];
    label_results{end+1} = reslabs;
    %Register each atlas image to the target
    reg_cmd = sprintf('%s/reg_aladin -ref %s -flo %s -aff %s -res %s',...
                  nr_path,          tgt_fname, moving, aff,    res);
    sr = system(reg_cmd);    
    
    %Transform the atlas labels to the target
    tform_cmd = sprintf('%s/reg_resample -ref %s -flo %s -aff %s -res %s -inter 0',...
        nr_path, tgt_fname, label,aff,reslabs);
   st = system(tform_cmd); 
end

%Now load in all of the labels and get the centroid
for i=1:numel(label_results)
    lab_nii = load_untouch_nii_gz(label_results{i});
    if i==1
        all_labels = zeros(lab_nii.hdr.dime.dim(2),...
                           lab_nii.hdr.dime.dim(3),...
                           lab_nii.hdr.dime.dim(4),...
                           numel(label_results));
    end
    all_labels(:,:,:,i) = lab_nii.img==eye_label;
end

%Probability map
sum_labels = sum(all_labels,4);
eye_prob = sum_labels./max(sum_labels(:));

mask = eye_prob > thresh;

%Find the eyes
s = regionprops(mask,'Area','Centroid');
centroids = cat(1,s.Centroid);
if isempty(centroids)
    error('Could not localize any centroids');
end
%Swap x/y to be row/col
tmp = centroids(:,1);
centroids(:,1) = centroids(:,2);
centroids(:,2) = tmp;
areas = cat(1,s.Area);
[~,sort_idx] = sort(areas, 'descend');
sorted_centroids = centroids(sort_idx,:);
%Get the two biggest
eye_centroids = sorted_centroids(1:2,:);

        
%------------- END OF CODE --------------
