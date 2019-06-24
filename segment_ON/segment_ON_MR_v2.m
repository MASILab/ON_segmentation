function segment_ON_MR_v2(test_images,atlas_dir,ANTS_path,niftyreg_path,utils_path,output_dir,mipav_path,varargin)
%SEGMENT_ON_MR_V2 - Run multi-atlas optic nerve segmentation pipeline on all image files in an
%input directory using the atlases in atlas_dir
%
% Syntax:  segment_ON_MR_v2(input_dir,atlas_dir,ANTS_path,utils_path,output_dir,mipav_path,[leave_out])
%
% Inputs:
%    test_images - Input image(s) to be segmented
%    atlas_dir - Directory of the atlas, should have subdirectories atlas_images and atlas_labels
%    ANTS_path - path to ANTs registration bin
%    niftyreg_path - path to niftyreg for affine localization
%    utils_path - path to matlab utilities in masimatlab
%    output_dir - Directory to save the results
%    mipav_path - Path to mipav (for calling jist for label fusion)
%    leave_out - (Optional) the atlas number (based on atlas image order)
%    to be excluded, for use with cross validation.
%
% Outputs:
%    None
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: tprintf, get_file_name
%
% See also: register_ON_MR_v2,  fuse_ON_MR_v2, init_ON_MR_v2
%
% Author:  harrigr
% Date:    25-Nov-2015 13:20:27
% Version: 2.0
% Changelog:
%
% 20-Nov-2015 13:20:27 - initial creation
%
%------------- BEGIN CODE --------------

jlf_dir = utils_path; % location of jointfusion executable

narginchk(8,9);
if nargin==9
    leave_out = varargin{1};
else
    leave_out = -1;
end

if ~iscellstr(test_images)
    if ischar(test_images)
        test_images = {test_images};
    else
        error('Input must be a filename or cell array of file names');
    end
end

tic;
addpath(utils_path)
useCropping = true;

boxtprintf('Initializing');
%This is not a great way to do this...
[ atlas_images,atlas_labels ,nrr_dir] = init_ON_MR_v2( test_images, atlas_dir, output_dir, useCropping);
[ full_atlas_images,full_atlas_labels ,~] = init_ON_MR_v2( test_images, atlas_dir, output_dir, false);

tprintf('Found %d atlases with matching labels\n',numel(atlas_images));
tprintf('Segmenting %d target images with these atlases\n',numel(test_images));
boxtprintf('Beginning processing...');

%For each target image:
for target = 1:length(test_images)

    %Leave one out for cross validation
    if leave_out ~= -1
        warning('SEGMENT_ON_MR_V2:Leaving atlas image out, this feature should only be used for cross validation');
        %         loo_atlas_image = atlas_images{leave_out};
        atlas_images(leave_out) = [];
        %         loo_atlas_label = atlas_labels{leave_out};
        atlas_labels(leave_out) = [];
    end

    %% Localization and cropping
    cropped_tgt_dir = [output_dir,filesep,'targets'];
    make_dir_if_doesnt_exist(cropped_tgt_dir);
    crop_bnd_file = [cropped_tgt_dir,filesep,get_file_name(test_images{target}),'_crop.mat'];
    if exist(crop_bnd_file,'file')~=0
        tprintf('Loading cropped target from file\n')
        load(crop_bnd_file);
        %Replace the dir of the cropped fname with the output directory from this run because it may be different
        cropped_fname = [cropped_tgt_dir,filesep, get_file_name(cropped_fname), '.nii.gz'];
    else
        tprintf('Cropping image\n')
        eye_centroids = localize_ON_MR_affine(test_images{target}, output_dir, ...
            niftyreg_path,full_atlas_images,full_atlas_labels, 3, 0.6);

        [cropped_fname,sz,crop_min,crop_max] = crop_ON_MR_v2(test_images{target},eye_centroids,cropped_tgt_dir);
        save(crop_bnd_file,'eye_centroids','crop_min','crop_max','sz','cropped_fname');
    end

    %% non-rigid registration
    boxtprintf('Non-Rigid Registration Begins');
    test_image= test_images{target};
    target_name = get_file_name(test_image);
    result_dir = [nrr_dir, filesep, sprintf('result/result_%s',target_name)];

    result  = register_ON_MR_v2( ANTS_path,cropped_fname,atlas_images,atlas_labels,result_dir );
    if result~=0, error('SEGMENT_ON_MR_v2::ERROR EXECUTING REGISTRATION');end
    boxtprintf('Non-Rigid Registration Complete')

    %% perform NLSS label fusion
    boxtprintf('beginning label fusion')

    [result,fuse_files]  = fuse_ON_MR_v2( cropped_fname,result_dir,atlas_labels,...
        atlas_images,output_dir,mipav_path, jlf_dir );
    if result~=0
        error('SEGMENT_ON_MR_v2::ERROR FUSING LABELS')
    end

    %% Uncrop the label to be the same size as the target image and save it back out
    boxtprintf('Uncropping label results');
    for i=1:numel(fuse_files)
        tprintf('Uncropping %s\n',fuse_files{i});
        result = uncrop_ON_MR_v2(fuse_files{i},sz,crop_min,crop_max);
        if result~=0
            error('SEGMENT_ON_MR_v2::ERROR UNCROPPING')
        end
    end

    boxtprintf('Result Saved');


end
