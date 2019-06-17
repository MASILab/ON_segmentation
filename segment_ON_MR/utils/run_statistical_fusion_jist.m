function cmds = run_statistical_fusion_jist(fuse_file, reg_labels, varargin)
% RUN_STATISTICAL_FUSION_JIST - run generalized statistical fusion using jist
%
% Four forms:
%
% (for STAPLE / Spatial STAPLE)
% 1) cmds = run_statistical_fusion_jist(fuse_file, reg_labels);
% 2) cmds = run_statistical_fusion_jist(fuse_file, reg_labels, opts);
%
% (for Non-Local STAPLE -- NLS / Non-Local Spatial STAPLE -- NLSS)
% 3) cmds = run_statistical_fusion_jist(fuse_file, reg_labels, ...
%                                       target_name, reg_ims);
% 4) cmds = run_statistical_fusion_jist(fuse_file, reg_labels, ...
%                                       target_name, reg_ims, opts);
%
% Input: fuse_file - the output fused file
%        reg_labels - the registered labels names (cell array)
%        target_name - (optional) the target image name
%        reg_ims - (optional) the registered atlas names (cell array)
%        opts - (optional) the options
%
% Output: cmds - the cell array of output commands
%              - to run on your local machine, run system(cmds{1});
%
% --- Available Options ---
%
% * STAPLE Options *
% opts.epsilon - Convergence Factor (default: 1e-4)
% opts.maxiter - Maximum number of iterations (default: 100)
% opts.consensus_thresh - consensus threshold (default: 0.99)
% opts.prior - Prior Type ('Global', 'Voxelwise', 'Weighted-Voxelwise')
%              default: 'Voxelwise'
% opts.hierarchyfile - the hierarchy text file (default: NONE)
%
% * Spatially Varying Options *
% opts.sv_window - Window size in image units (default: [5 5 5 0])
% opts.sv_bias - amount of bias applied to local performance (default: 0)
%              - Note: opts.sv_bias = 1 -- fully global
%              - Note: opts.sv_bias = 0 -- fully local
% opts.sv_augment - Augment local scalar performance model (default: 'false')
%
% * Patch Weighting Options *
% opts.weighttype - weighting type (default: 'MSD')
% opts.ns - search neighborhood size in image units (default: [2 2 2 0])
% opts.nc - patch neighborhood size in image units (default: [2 2 2 0])
% opts.sp_stdev - search standard deviation (default: [1.5 1.5 1.5 0])
% opts.weightstdev - patch weighting standard deviation (default: 0.15)
% opts.localsel - the local selection threshold (default: 0)
% opts.globalsel - the global selection threshold (default: 0)
% opts.use_norm - Use Intensity Normalization (default: 'true')
%
% * Patch Selection Options *
% opts.sel_type - patch selection type (default: 'Jaccard')
% opts.sel_thresh - patch selection threshold (default: 0.05)
% opts.num_keep - the # of patches to keep for each voxel (default: 150)
%
% * Run Options *
% opts.mipav - the mipav install location (default: [getenv('HOME'), '/mipav/'])
% opts.jvmmemval - amount of java heap memory (default: '6000m')
% opts.plugindir - plugins directory loc (default: [opts.mipav, '/plugins/'])
% opts.debuglvl - the debug (verbosity) level (default: 2)

cmds = {};

if length(varargin) == 0
    target_name = [];
    reg_ims = [];
    opts = struct;
elseif length(varargin) == 1
    target_name = [];
    reg_ims = [];
    opts = varargin{1};
elseif length(varargin) == 2
    target_name = varargin{1};
    reg_ims = varargin{2};
    opts = struct;
elseif length(varargin) == 3
    target_name = varargin{1};
    reg_ims = varargin{2};
    opts = varargin{3};
else
    error('Too many input arguments');
end

% STAPLE options
if ~isfield(opts, 'epsilon'), opts.epsilon = 1e-4; end
if ~isfield(opts, 'maxiter'), opts.maxiter = 100; end
if ~isfield(opts, 'consensus_thresh'), opts.consensus_thresh = 0.99; end
if ~isfield(opts, 'prior'), opts.prior = 'Voxelwise'; end
if ~isfield(opts, 'hierarchyfile'), opts.hierarchyfile = ''; end

% Spatially Varying options
if ~isfield(opts, 'sv_window'), opts.sv_window = [5 5 5 0]; end
if ~isfield(opts, 'sv_bias'), opts.sv_bias = 0.0; end
if ~isfield(opts, 'sv_augment'), opts.sv_augment = 'false'; end

% weighted voting options
if ~isfield(opts, 'ns'), opts.ns = [3 3 3 0]; end
if ~isfield(opts, 'nc'), opts.nc = [2 2 2 0]; end
if ~isfield(opts, 'sp_stdev'), opts.sp_stdev = [1.5 1.5 1.5 0]; end
if ~isfield(opts, 'weightstdev'), opts.weightstdev = 0.25; end
if ~isfield(opts, 'weighttype'), opts.weighttype = 'MSD'; end
if ~isfield(opts, 'localsel'), opts.localsel = 0.1; end
if ~isfield(opts, 'globalsel'), opts.globalsel = 0.0; end
if ~isfield(opts, 'use_norm'), opts.use_norm = 'true'; end

% patch selection options
if ~isfield(opts, 'sel_type'), opts.sel_type = 'Jaccard'; end
if ~isfield(opts, 'sel_thresh'), opts.sel_thresh = 0.05; end
if ~isfield(opts, 'num_keep'), opts.num_keep = 150; end

% constant options
if ~isfield(opts, 'mipav'), opts.mipav = [getenv('HOME'), '/mipav/']; end
if ~isfield(opts, 'jvmmemval'), opts.jvmmemval = '8000m'; end
if ~isfield(opts, 'plugindir'), opts.plugindir = [opts.mipav, '/plugins/']; end
if ~isfield(opts, 'debuglvl'), opts.debuglvl = 2; end

% set the atlas strings
atlas_seg_str = '';
for i = 1:length(reg_labels)
    atlas_seg_str = sprintf('%s%s;', atlas_seg_str, reg_labels{i});
end
atlas_seg_str = atlas_seg_str(1:end-1);

if length(reg_ims) > 0
    atlas_im_str = '';
    for i = 1:length(reg_ims)
        atlas_im_str = sprintf('%s%s;', atlas_im_str, reg_ims{i});
    end
    atlas_im_str = atlas_im_str(1:end-1);
end

javaloc = [opts.mipav, '/jre/bin/java'];
if ~exist(javaloc, 'file')
    [~, javaloc] = system('which java');
    javaloc = javaloc(1:end-1);
end

% set the prefix
mipavjava_cmd = sprintf(['%s -Xms%s -XX:+UseSerialGC -Xmx%s -classpath %s:%s:', ...
                         '`find %s -name \\*.jar | grep -v Uninstall | ', ...
                         'sed "s#%s#:%s#" | tr -d "\\n" | sed "s/^://"`'], ...
                         javaloc, opts.jvmmemval, opts.jvmmemval, opts.plugindir, ...
                         opts.mipav, opts.mipav, opts.mipav, opts.mipav);
run_str = 'edu.jhu.ece.iacl.jist.cli.run';
class_str = 'edu.vanderbilt.masi.plugins.labelfusion.PluginStatisticalFusion';
full_run_str = sprintf('%s %s %s', mipavjava_cmd, run_str, class_str);

% make output file full path
if ~strcmp(fuse_file(1), '/')
    fuse_file = fullfile(pwd, fuse_file);
end

% set the options
opts_str = '';
opts_str = sprintf('%s -inAtlas "%s"', opts_str, atlas_seg_str);
if length(reg_ims) > 0
    opts_str = sprintf('%s -inAtlas2 "%s"', opts_str, atlas_im_str);
end
if length(target_name) > 0
    opts_str = sprintf('%s -inTarget "%s"', opts_str, target_name);
end
opts_str = sprintf('%s -inConvergence %f', opts_str, opts.epsilon);
opts_str = sprintf('%s -inMaximum %d', opts_str, opts.maxiter);
opts_str = sprintf('%s -inConsensus %f', opts_str, opts.consensus_thresh);
opts_str = sprintf('%s -inPrior %s', opts_str, opts.prior);
if length(opts.hierarchyfile) > 0
    opts_str = sprintf('%s -inHierarchy %s', opts_str, opts.hierarchyfile);
end
opts_str = sprintf('%s -inWindow %d', opts_str, opts.sv_window(1));
opts_str = sprintf('%s -inWindow2 %d', opts_str, opts.sv_window(2));
opts_str = sprintf('%s -inWindow3 %d', opts_str, opts.sv_window(3));
opts_str = sprintf('%s -inWindow4 %d', opts_str, opts.sv_window(4));
opts_str = sprintf('%s -inBias %f', opts_str, opts.sv_bias);
opts_str = sprintf('%s -inAugment %s', opts_str, opts.sv_augment);
opts_str = sprintf('%s -inWeighting %s', opts_str, opts.weighttype);
opts_str = sprintf('%s -inSearch %d', opts_str, opts.ns(1));
opts_str = sprintf('%s -inSearch2 %d', opts_str, opts.ns(2));
opts_str = sprintf('%s -inSearch3 %d', opts_str, opts.ns(3));
opts_str = sprintf('%s -inSearch4 %d', opts_str, opts.ns(4));
opts_str = sprintf('%s -inPatch %d', opts_str, opts.nc(1));
opts_str = sprintf('%s -inPatch2 %d', opts_str, opts.nc(2));
opts_str = sprintf('%s -inPatch3 %d', opts_str, opts.nc(3));
opts_str = sprintf('%s -inPatch4 %d', opts_str, opts.nc(4));
opts_str = sprintf('%s -inSearch5 %d', opts_str, opts.sp_stdev(1));
opts_str = sprintf('%s -inSearch6 %d', opts_str, opts.sp_stdev(2));
opts_str = sprintf('%s -inSearch7 %d', opts_str, opts.sp_stdev(3));
opts_str = sprintf('%s -inSearch8 %d', opts_str, opts.sp_stdev(4));
opts_str = sprintf('%s -inDifference %f', opts_str, opts.weightstdev);
opts_str = sprintf('%s -inGlobal %f', opts_str, opts.globalsel);
opts_str = sprintf('%s -inLocal %f', opts_str, opts.localsel);
opts_str = sprintf('%s -inUse %s', opts_str, opts.use_norm);
opts_str = sprintf('%s -inSelection %s', opts_str, opts.sel_type);
opts_str = sprintf('%s -inSelection2 %f', opts_str, opts.sel_thresh);
opts_str = sprintf('%s -inNumber %d', opts_str, opts.num_keep);
opts_str = sprintf('%s -xDebugLvl %d', opts_str, opts.debuglvl);

% create the command
cmds{1} = sprintf('%s %s -outLabel %s\n', full_run_str, opts_str, fuse_file);

