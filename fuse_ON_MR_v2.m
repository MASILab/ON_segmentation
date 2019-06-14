function [ result, varargout ] = fuse_ON_MR_v2(testimage,result_dir,atlaslabels,atlasimages,output_dir,mipav_path, jlf_path )
%fuse ON_MR labels
%Author: Rob Harrigan
%Vanderbilt University
%March 2014
testimageName = get_file_name(testimage);

nAtlases = length(atlasimages);
target_name=testimage;
obs_label=cell(nAtlases,1);
obs_image=cell(nAtlases,1);

%These should really be passed back from the registration script...
for part=1:nAtlases
    atlas_label_name = get_file_name(atlaslabels{part});
    atlas_image_name = get_file_name(atlasimages{part});
    l=( sprintf('%s/labelresult_%s.nii.gz' , result_dir,atlas_label_name));
    im=( sprintf('%s/atlasimageresult_%s.nii.gz' , result_dir,atlas_image_name));
    
    %holds the atlas image and label RESULT locations
    obs_label{part,:}=l;
    obs_image{part,:}=im;
    
end

fuse_file= sprintf('%s/label_fusion/NLSS/%s-SEG.nii.gz',output_dir,testimageName);
if ~exist(fuse_file,'file')
    
    
    opts.jvmmemval = '8000M';
    opts.mipav = mipav_path;
    opts.sv_window=[3 3 3 0];
    opts.ns= [2 2 2 0];
    opts.nc=[1 1 1 0];
    opts.sp_stdev=[1.5 1.5 1.5 0];
    opts.weightstdev=0.5;
    opts.weighttype='Mixed';
    opts.localsel=0.0;
    
    %   Input: fuse_file - the output fused file
    %          reg_labels - the registered labels names (cell array)
    %          target_name - (optional) the target image name
    %          reg_ims - (optional) the registered atlas names (cell array)
    %          opts - (optional) the options
    
    %Oldcmds(1) = run_nlss_fusion_jist(target_name,obs_label,obs_image, fuse_file, fuseloc, opts);
    cmds(1) = run_statistical_fusion_jist(fuse_file, obs_label, target_name, obs_image, opts);
    clear opts;
    
    %cmds{1} = prepend_jist_cluster_prefix(cmds{1}, 0, sprintf('%s/label_fusion/temp/',output_dir),sprintf('%s_%s',testimage,atlas{part}));
    tprintf('Running NLSS with command:\n%s\n',cmds{1});
    result = system(cmds{1});
end
%% JLF
registered_image_str = strjoin(obs_image',' ');
registered_label_str = strjoin(obs_label',' ');

jlf_fuse_file= sprintf('%s/label_fusion/JLF/%s-SEG.nii.gz',output_dir,testimageName);
if ~exist(jlf_fuse_file,'file')
    jlf_cmd = sprintf('%s/jointfusion 3 1 -tg %s -g %s -l %s %s',...
        jlf_path,    testimage, registered_image_str, registered_label_str, jlf_fuse_file);
    tprintf('Running JLF with command:\n%s\n',jlf_cmd);
    system(jlf_cmd);
end




if nargout>1
    varargout{1} = {fuse_file,jlf_fuse_file};
end

end
