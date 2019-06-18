function ON_MR_segmentation_pdf_report_v2_0_0(raw_fname, seg_fname, pdf_fname, tmp_dir, proj_name, subj_name, expr_name, atlas_path, scan_type)
% ON_MR_segmentation_pdf_report_v2_0_0 - Generates the summary PDF for ON
% segmentation
%
% ON_MR_segmentation_pdf_report_v2_0_0(raw_fname, seg_fname, pdf_fname, tmp_dir)
%
% Input: raw_fname - the raw (intensity image filename -- .nii.gz)
%        seg_fname - the estimated segmentation -- .nii.gz
%        pdf_fname - the final pdf filename
%        tmp_dir - the directory to store temporary output
%        proj_name - the name of the project
%        subj_name - the name of the subject
%        expr_name = the name of the experiment
%
% Output: None.
%
% Andrew Asman via Frederick Bryan, Oct 2013
% Adapted for ON use by Robert Harrigan, January 2016



% load the figure
fig = openfig('ON_MR_segmentation_template.fig','new');
fig_handles = guihandles(fig);

%
% Set all of the basic information
%
set(fig_handles.text20,'String',proj_name);
set(fig_handles.text30,'String',subj_name);
set(fig_handles.text28,'String',expr_name);
set(fig_handles.text35,'String', date);
axes(fig_handles.axes30); p=text(0,0,sprintf('Raw Image')); set(p,'rotation',90,'position',[0.5 0.5],'FontSize',12,'FontWeight','bold', 'HorizontalAlignment','center'); axis off;
axes(fig_handles.axes31); p=text(0,0,sprintf('Slicewise\nSegmentation')); set(p,'rotation',90,'position',[0.5 0.5],'FontSize',12,'FontWeight','bold', 'HorizontalAlignment','center'); axis off;
axes(fig_handles.axes32); p=text(0,0,sprintf('Rendering\nOverlay')); set(p,'rotation',90,'position',[0.5 0.5],'FontSize',12,'FontWeight','bold', 'HorizontalAlignment','center'); axis off;
axes(fig_handles.axes33); p=text(0,0,sprintf('Volume\nRendering')); set(p,'rotation',90,'position',[0.5 0.5],'FontSize',12,'FontWeight','bold', 'HorizontalAlignment','center'); axis off;
set(fig_handles.text47, 'String', 'Version 2.0.0');
set(fig_handles.text49, 'String', sprintf('Scan type: %s run with Atlas: %s',scan_type, atlas_path));

% load('braincolor_cmap.mat');
raw = load_untouch_nii_gz(raw_fname);
seg = load_untouch_nii_gz(seg_fname);

%If it is a dual echo, just make the PDF from the proton density image
if numel(size(raw.img))==4
    raw.img = raw.img(:,:,:,1);
end
if numel(size(seg.img))==4
    seg.img = seg.img(:,:,:,1);
end

% set some label information
load('ON_colormaps.mat');
switch proj_name
    case {'CALSER', 'PHOTON'}
        cmap_orig_vals = CALSER_cmap;
        seg_ON = seg.img == 1;
    case 'MR_ONS'
        cmap_orig_vals = VISTA_cmap;
        seg_ON = (seg.img == 1 | seg.img == 2);
    otherwise
        warning('ON_MR_SEGMENTATION_PDF_REPORT_v2: running on an unknown project, please create a colormap, using default CALSER colormap');
        cmap_orig_vals = CALSER_cmap;
        seg_ON = seg.img == 1;
end
    
ll = unique(seg.img);
ll = ll(2:end); %Drop the bg
la = ones(size(ll));

% set the default options
default_opts.fignum = 99;
optimal_ilim = get_optimal_ilim(double(raw.img), double(seg.img));
default_opts.ilim = optimal_ilim;
default_opts.labels = ll;
default_opts.labelcolors = cmap_orig_vals;
default_opts.material = 'dull';
default_opts.slicealpha = 0.9;
default_opts.cr_buffer = -1;

%Use slices which are medial to the labels
[~,default_opts.xslices] = max(sum(sum(seg_ON,2),3)); %Sagittal
% [~,default_opts.yslices] = max(sum(sum(seg_ON,1),3)); %Coronal
AP_start = find(sum(sum(seg_ON,1),3)>0,1,'first');
AP_end = find(sum(sum(seg_ON,1),3)>0,1,'last');
% default_opts.yslices = round(mean([AP_start,AP_end])); %Center of ON
default_opts.yslices = round(prctile(AP_start:AP_end,65)); %Experimentally slightly anterior of center
[~,default_opts.zslices] = max(sum(sum(seg_ON,1),2)); %Axial
pixdim = raw.hdr.dime.pixdim(2:4);
%
% Do the Slice-Based Images
%
axes(fig_handles.axes1);
plot_segmentation_overlay(permute(raw.img, [2 1 3]), ...
                          permute(seg.img, [2 1 3]), ...
                          0.0, cmap_orig_vals, default_opts.ilim, ...
                          default_opts.zslices);
daspect(pixdim);

axes(fig_handles.axes18);
plot_segmentation_overlay(flipdim(permute(raw.img, [3 1 2]), 1), ...
                          flipdim(permute(seg.img, [3 1 2]), 1), ...
                          0.0, cmap_orig_vals, default_opts.ilim, ...
                          default_opts.yslices);
daspect([pixdim(3),pixdim(1),pixdim(2)]);

axes(fig_handles.axes19);
plot_segmentation_overlay(flipdim(permute(raw.img, [3 2 1]), 1), ...
                          flipdim(permute(seg.img, [3 2 1]), 1), ...
                          0.0, cmap_orig_vals, default_opts.ilim, ...
                          default_opts.xslices);
daspect([pixdim(3),pixdim(2),pixdim(1)]);

axes(fig_handles.axes21);
plot_segmentation_overlay(permute(raw.img, [2 1 3]), ...
                          permute(seg.img, [2 1 3]), ...
                          0.6, cmap_orig_vals, default_opts.ilim, ...
                          default_opts.zslices);
daspect(pixdim);

axes(fig_handles.axes22);
plot_segmentation_overlay(flipdim(permute(raw.img, [3 1 2]), 1), ...
                          flipdim(permute(seg.img, [3 1 2]), 1), ...
                          0.6, cmap_orig_vals, default_opts.ilim, ...
                          default_opts.yslices);
daspect([pixdim(3),pixdim(1),pixdim(2)]);

axes(fig_handles.axes23);
plot_segmentation_overlay(flipdim(permute(raw.img, [3 2 1]), 1), ...
                          flipdim(permute(seg.img, [3 2 1]), 1), ...
                          0.6, cmap_orig_vals, default_opts.ilim, ...
                          default_opts.xslices);
daspect([pixdim(3),pixdim(2),pixdim(1)]);

%
% Do the Volume-Based Images
%
%% Row 3
opts = default_opts;
opts.labelcolors = opts.labelcolors(2:end,:);
opts.azimuth = 90;
opts.elevation = 90;
render_3D_labels(raw.img, seg.img, opts);
set(gcf, 'color', 'w');
set(gca, 'units', 'pixels');
fr = getframe(gcf, get(gca, 'Position'));
axes(fig_handles.axes24);
cr = determine_cropping_region(min(fr.cdata, [], 3)<255, 0);
imshow(fr.cdata(cr(1):cr(2), cr(3):cr(4), :));
daspect(pixdim);

opts = default_opts;
opts.labelcolors = opts.labelcolors(2:end,:);
opts.azimuth = 90;
opts.elevation = 0;
render_3D_labels(raw.img, seg.img, opts);
set(gcf, 'color', 'w');
set(gca, 'units', 'pixels');
fr = getframe(gcf, get(gca, 'Position'));
axes(fig_handles.axes25);
cr = determine_cropping_region(min(fr.cdata, [], 3)<255, 0);
imshow(fr.cdata(cr(1):cr(2), cr(3):cr(4), :));
daspect([pixdim(3),pixdim(1),pixdim(2)]);

opts = default_opts;
opts.labelcolors = opts.labelcolors(2:end,:);
opts.azimuth = 0;
opts.elevation = 0;
render_3D_labels(raw.img, seg.img, opts);
set(gcf, 'color', 'w');
set(gca, 'units', 'pixels');
fr = getframe(gcf, get(gca, 'Position'));
axes(fig_handles.axes26);
cr = determine_cropping_region(min(fr.cdata, [], 3)<255, 0);
imshow(fr.cdata(cr(1):cr(2), cr(3):cr(4), :));
daspect([pixdim(3),pixdim(2),pixdim(1)]);

%% Row 4
opts = default_opts;
opts.xslices=[];opts.yslices=[];opts.zslices=[];
opts.labelcolors = opts.labelcolors(2:end,:);
opts.labelalphas = la;
opts.azimuth = 90;
opts.elevation = 70;
render_3D_labels(raw.img, seg.img, opts);
set(gcf, 'color', 'w');
set(gca, 'units', 'pixels');
fr = getframe(gcf, get(gca, 'Position'));
axes(fig_handles.axes27);
cr = determine_cropping_region(min(fr.cdata, [], 3)<255, 0);
imshow(fr.cdata(cr(1):cr(2), cr(3):cr(4), :));
daspect(pixdim);

opts = default_opts;
opts.xslices=[];opts.yslices=[];opts.zslices=[];
opts.labelcolors = opts.labelcolors(2:end,:);
opts.labelalphas = la;
opts.azimuth = 70;
opts.elevation = 10;
render_3D_labels(raw.img, seg.img, opts);
set(gcf, 'color', 'w');
set(gca, 'units', 'pixels');
fr = getframe(gcf, get(gca, 'Position'));
axes(fig_handles.axes28);
cr = determine_cropping_region(min(fr.cdata, [], 3)<255, 0);
imshow(fr.cdata(cr(1):cr(2), cr(3):cr(4), :));
daspect([pixdim(3),pixdim(1),pixdim(2)]);

opts = default_opts;
opts.xslices=[];opts.yslices=[];opts.zslices=[];
opts.labelcolors = opts.labelcolors(2:end,:);
opts.labelalphas = la;
opts.azimuth = 110;
opts.elevation = 10;
render_3D_labels(raw.img, seg.img, opts);
set(gcf, 'color', 'w');
set(gca, 'units', 'pixels');
fr = getframe(gcf, get(gca, 'Position'));
axes(fig_handles.axes29);
imshow(fr.cdata);
cr = determine_cropping_region(min(fr.cdata, [], 3)<255, 0);
imshow(fr.cdata(cr(1):cr(2), cr(3):cr(4), :));
daspect([pixdim(3),pixdim(2),pixdim(1)]);

% temporarily write the result as postscript
set(fig,'PaperType','usletter', 'PaperPositionMode','auto');
temp_ps = [tmp_dir, '/temp.ps'];
print('-dpsc2','-r400', temp_ps, fig);

% conver the postscript to the file pdf file
cmmd = ['ps2pdf -dPDFSETTINGS=/prepress ' temp_ps ' ' pdf_fname];
[status,msg]=system(cmmd);
if status~=0
    fprintf('\n Could not cleanly create pdf file from ps.\n');
    disp(msg);
end

