function [ result ] = register_ON_MR_v2( ANTS_path,test_image,atlas_images,atlas_labels,out_dir )
%Perform registration for ON_MR
%All inputs are fully qualified path filenames
%Author: Rob Harrigan
%Vanderbilt University
%November 2015

%Make sure each image has a label:
if (length(atlas_images) ~= length(atlas_labels))
    fprintf('SEGMENT_ON_MR_v2::REGISTER_ON_MR_v2::Atlas must have the same number of labels and images');
else
    nAtlases = length(atlas_images);
end
part=1;
nErrors=ones(nAtlases,1);

while part <= nAtlases
    atlas_image_name = get_file_name(atlas_images{part});
    atlas_label_name = get_file_name(atlas_labels{part});

    ANTS_call = ...
        sprintf('%s/ANTS 3 -m CC[ %s , %s,1,2] ',...
                    ANTS_path,test_image, atlas_images{part});
    ANTS_call = [ANTS_call , ...
        sprintf(' -o %s/output_transform_%s.nii.gz ',...
        out_dir,atlas_image_name)];
    ANTS_call = [ANTS_call , ...
        '-r Gauss[2,0] -t SyN[0.5] -i 30x99x11 --use-Histogram-Matching ',...
        '--number-of-affine-iterations 10000x10000x10000x10000x10000'];
    boxtprintf('Registering atlas %s',atlas_image_name);
    tprintf('Call: %s\n',ANTS_call);
    if exist(sprintf('%s/output_transform_%sWarp.nii.gz',out_dir,atlas_image_name),'file')==0
        status = system(ANTS_call);
    else
        tprintf('Output transform exists, skipping registration\n');
        status=0;
    end

    warp_label_call = sprintf('%s/WarpImageMultiTransform 3 ', ANTS_path);
    warp_label_call = [warp_label_call,...
        sprintf('%s  %s/labelresult_%s.nii.gz ',...
        atlas_labels{part},out_dir,atlas_label_name)];
    warp_label_call = [warp_label_call,...
        sprintf(' -R %s  %s/output_transform_%sWarp.nii.gz ',...
        test_image,out_dir,atlas_image_name)];
    warp_label_call = [warp_label_call,...
        sprintf(' %s/output_transform_%sAffine.txt --use-NN ',...
        out_dir,atlas_image_name)];
    boxtprintf(' Warping atlas label %s ',atlas_label_name);
    tprintf('Call: %s\n',warp_label_call);
    if exist(sprintf('%s/labelresult_%s.nii.gz',out_dir,atlas_label_name),'file')==0
        status2 = system(warp_label_call);
    else
        tprintf('Warped label file exists, skipping warp\n');
        status2=0;
    end

    warp_image_call = sprintf('%s/WarpImageMultiTransform 3 ',ANTS_path);
    warp_image_call = [warp_image_call,...
        sprintf('%s %s/atlasimageresult_%s.nii.gz ',...
        atlas_images{part},out_dir,atlas_image_name)];
    warp_image_call = [warp_image_call,...
        sprintf(' -R %s %s/output_transform_%sWarp.nii.gz ',...
        test_image,out_dir,atlas_image_name)];
    warp_image_call = [warp_image_call,...
        sprintf(' %s/output_transform_%sAffine.txt ',out_dir,atlas_image_name)];
    boxtprintf('Warping atlas image %s',atlas_image_name);
    tprintf('Call: %s\n',warp_image_call);
    if exist(sprintf('%s/atlasimageresult_%s.nii.gz',out_dir,atlas_image_name),'file')==0
        status3 = system(warp_image_call);
    else
        tprintf('Warped image file exists, skipping warp\n');
        status3=0;
    end

    result=status+status2+status3;

    if result==0
        %If it was a success then do the next registration
        part=part+1;
    else
        %if it fails try once more...
        nErrors(part)=nErrors(part)+1;
       if nErrors(part)>=2
           error('ON_MR_SEGMENTATION::REGISTER_ON_MR::REGISTRATION FAILED 3 TIMES IN A ROW');
       end
    end

end

end

