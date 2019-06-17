function [ atlas_images,atlas_labels,nrr_dir ] = init_ON_MR_v2( test_images, atlas_dir,output_dir, usecropped )
%Creates the directory structure for the MR ON segmentation
%Author: Rob Harrigan
%Vanderbilt University 
%November 2015


tprintf('checking if output directories exists\n')
%Make sure output directory exists(it should, spider creates it)
if isempty(dir(output_dir)), mkdir(output_dir); end

%Get the atlas images
if usecropped
    atlas_image_dir = [atlas_dir,filesep,'cropped_images'];
else
    atlas_image_dir = [atlas_dir,filesep,'atlas_images'];
end
atlas_images = get_fnames_dir(atlas_image_dir,'*.nii.gz');
if numel(atlas_images)==0, error('INIT_ON_MR_v2 :: No atlas images found, check the atlas structure');end


%Get the atlas labels 
if usecropped
    atlas_label_dir = [atlas_dir,filesep,'cropped_labels'];
else
    atlas_label_dir = [atlas_dir,filesep,'atlas_labels'];
end
atlas_labels = get_fnames_dir(atlas_label_dir,'*.nii.gz');
if numel(atlas_labels)==0, error('INIT_ON_MR_v2 :: No atlas labels found, check the atlas structure');end

%Make sure we have matches
if numel(atlas_images)~=numel(atlas_labels),error('INIT_ON_MR_v2 :: Could not establish matching atlas images and labels, check atlas status');end

%Create the non rigid registration results directory
tprintf('creating output directory structure\n');
nrr_dir=[output_dir,filesep,'non_rigid_registration'];
if exist(nrr_dir,'dir')==0,mkdir(nrr_dir);end

%Create the label fusion results directory
lf_dir=[output_dir,filesep,'label_fusion'];
if exist(lf_dir,'dir')==0,mkdir(lf_dir);end

tprintf('creating labelfusion directory structure\n')

%Create NLSS output dir
nlss_dir=[lf_dir,filesep,'NLSS'];
if exist(nlss_dir,'dir')==0,mkdir(nlss_dir);end
jlf_dir=[lf_dir,filesep,'JLF'];
if exist(jlf_dir,'dir')==0,mkdir(jlf_dir);end

%non_rigid registration files
tprintf('creating non rigid registration files\n')
result_dir=[nrr_dir,'/result'];
if exist(result_dir,'dir')==0,mkdir(result_dir);end

pbs_dir=[nrr_dir,'/pbs'];
if exist(pbs_dir,'dir')==0,mkdir(pbs_dir);end

%Create each result directory
for i=1:length(test_images)
    new_dir=[result_dir,filesep,'result_',get_file_name(test_images{i})];
    if exist(new_dir,'dir')==0,mkdir(new_dir);end
end

%Create folders for registration scripts (for use on cluster)
for i=1:length(test_images)
    new_dir=[pbs_dir,'/pbs_',get_file_name(test_images{i})];
    if exist(new_dir,'dir')==0,mkdir(new_dir);end
end

boxtprintf('intermediate folders have been created')



end

