function ON_conjgrad_3D_v2(Subj,Subjlabel,outDir,modulesPath,project,subject,experiment)
%ON_CONJGRAD_3D_V2 - Perform 3d consistent ON:sheath segmentation on a full
%volume. Runs fit_conjgrad, iteratively decreasing the tolerance for
%outliers until fit_conjgrad converges to a smooth solution.
%
% Syntax:  ON_conjgrad_3D_v2(Subj,Subjlabel,outDir,modulesPath,treesFile,project,subject,experiment)
%
% Inputs:
%    Subj - Path to the input image file, must be nii or nii.gz
%    Subjlabel - Path to the label file from initial segmentation
%    outDir - Directory to save the outputs
%    modulesPath - Path to ON_segmentation utilities (ON_segmentation/utils) 
%    project - Project name (for PDF)
%    subject - Subject name (for PDF)
%    experiment - Experiment name (for PDF)
%
% Outputs:
%    None - saves results in outDir
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: fit_conjgrad,  model_stpdesc
%
% Author:  harrigr
% Date:    18-May-2016 10:35:43
% Version: 1.0
% Changelog:
%
% 18-May-2016 10:35:43 - initial creation
tic;
treesFile = 'TreeBaggerObjects.mat';
%make sure we have modules to load niftis
addpath(genpath(modulesPath));
mFilePath = fileparts(mfilename('fullpath'));
tprintf('Running matlab script from %s\n',mFilePath);

%% Define Variables
rightON = 1;
leftON  = 2;
globes  = 3;
chiasm  = 6;
support=7;

%gradient descent options
opts.iter_max=70;
opts.keep_trying=true;
opts.save_gif=false;
opts.ftol=10e-12;  %default : 10e-12
opts.gradtol=10e-6;%default : 10e-6
opts.display=false;
input_basename = get_file_name(Subj);
%iterative fit parameters
nIters = 100;
nSD = linspace(3,0.1,nIters);

%% Load in the images in RAS orientation
if strcmp(Subj(end-1:end),'gz')
    im = load_untouch_nii_gz(Subj);
else
    im = load_untouch_nii(Subj);
end

if strcmp(Subjlabel(end-1:end),'gz')
    label = load_untouch_nii_gz(Subjlabel);
else
    label = load_untouch_nii(Subjlabel);
end

im = double(im.img);
% labelwHdr=label;
label = label.img;

sz=size(im);
% sliceSz=size(squeeze(im(:,fix(sz(2)/2),:)));

szl = size(label);
if sz~=szl
    warning('SIZE MISMATCH::label and image are not the same size, continuing anyway');
end

leftLabel  = label== leftON;
rightLabel = label==rightON;


%% calculate the medial axis in the coronal plane
%This assumes the images have been loaded in RAS
nSlices = size(leftLabel,2);
centroidsL = zeros(nSlices,2);
centroidsR = zeros(nSlices,2);
validL = zeros(nSlices,1);
validR = zeros(nSlices,1);
sigmaL = zeros(nSlices,1);
sigmaR = zeros(nSlices,1);
for slice=1:nSlices
    if sum(sum(leftLabel(:,slice,:)))>0
        tmp = regionprops(squeeze(leftLabel(:,slice,:)),'centroid','MajorAxisLength');
        centroidsL(slice,1:2) = tmp.Centroid;
        sigmaL(slice) = tmp.MajorAxisLength;
        validL(slice)=1;
    end

    if sum(sum(rightLabel(:,slice,:)))>0
        tmp = regionprops(squeeze(rightLabel(:,slice,:)),'centroid','MajorAxisLength');
        centroidsR(slice,1:2) = tmp.Centroid;
        sigmaR(slice) = tmp.MajorAxisLength;
        validR(slice)=1;
    end
end

rawCentroidsFileL = [outDir filesep input_basename '_rawCentroidsL.txt'];
rawCentroidsFileR = [outDir filesep input_basename '_rawCentroidsR.txt'];
save(rawCentroidsFileL,'centroidsL','-ascii','-double');
save(rawCentroidsFileR,'centroidsR','-ascii','-double');
rawCL = centroidsL;
rawCR = centroidsR;


%% Fit a cubic to fill in any missing points
%Here we predict L-R from the A-P values
z = (1:nSlices)';
firstL = find(validL,1,'first');
lastL = find(validL,1,'last');
firstR = find(validR,1,'first');
lastR = find(validR,1,'last');

%If any values are missing, fill them in with linear interpolation
missingL = (centroidsL(firstL:lastL,1) == 0) | (centroidsL(firstL:lastL,2) == 0);
missingR = (centroidsR(firstR:lastR,1) == 0) | (centroidsR(firstR:lastR,2) == 0);

slicesL = z(firstL:lastL);
RL_L = centroidsL(firstL:lastL,2);
slicesR = z(firstR:lastR);
RL_R = centroidsR(firstR:lastR,2);

%Then we'll fit a cubic
[p,~,muL] = polyfit(slicesL(~missingL),RL_L(~missingL),3);
new_centroidsL = polyval(p,slicesL,[],muL);
[p,~,muR] = polyfit(slicesR(~missingR),RL_R(~missingR),3);
new_centroidsR = polyval(p,slicesR,[],muR);

% figure;imagesc(im(:,:,30));colormap gray;axis image;
% hold on;
% scatter(slicesL,RL_L);
% plot(slicesL,new_centroidsL);
% scatter(slicesR,RL_R,'r');
% plot(slicesR,new_centroidsR,'r');

centroidsL(firstL:lastL,2) = new_centroidsL;
centroidsR(firstR:lastR,2) = new_centroidsR;

%Now do the I-S
IS_L = centroidsL(firstL:lastL,1);
IS_R = centroidsR(firstR:lastR,1);

[p,~,muL] = polyfit(slicesL(~missingL),IS_L(~missingL),3);
new_IS_L = polyval(p,slicesL,[],muL);

[p,~,muR] = polyfit(slicesR(~missingR),IS_R(~missingR),3);
new_IS_R = polyval(p,slicesR,[],muR);

centroidsL(firstL:lastL,1) = new_IS_L;
centroidsR(firstR:lastR,1) = new_IS_R;

%% Fit the ON iteratively
allOpL = zeros(sum(validL),10,nIters);
allOpR = zeros(sum(validR),10,nIters);
deltaCL = zeros(sum(validL),2,nIters);
deltaCR = zeros(sum(validR),2,nIters);
cmap = jet(numel(nSD));
for i=1:nIters
    boxtprintf('Beginning Iteration %d',i)
    %Fit the model, will pass in initial values after first iteration
    [outputL,outputR] = fit_conjgrad(im,centroidsL,centroidsR,...
        validL,validR,support,opts);
    %%save all of the outputs
    allOpL(:,:,i) = outputL;
    allOpR(:,:,i) = outputR;
    deltaCL(:,:,i) = outputL(:,8:9);
    deltaCR(:,:,i) = outputR(:,8:9);

    %%Smooth parameters with moving average
    %Left
    opL = outputL(:,2:9);
    maL = zeros(size(opL));
    sdL = zeros(size(opL,2),1);
    for j=1:size(opL,2) % for each of the 8 parameters
        maL(:,j) = smooth(opL(:,j),7);
        sdL(j) = std(maL(:,j));
    end
    %determine the parameters to keep, start with the smoothed pts and
    %replace any that were close with their final fit
    good_ptsL = abs(maL - opL)<repmat(sdL.*nSD(i),[1,size(opL,1)]).';
    paramsL = maL;
    paramsL(good_ptsL) = opL(good_ptsL);

    %Right
    opR = outputR(:,2:9);
    maR = zeros(size(opR));
    sdR = zeros(size(opR,2),1);
    for j=1:size(opR,2)
        maR(:,j) = smooth(opR(:,j),7);
        sdR(j) = std(maR(:,j));
    end
    good_ptsR = abs(maR - opR)<repmat(sdR.*nSD(i),[1,size(opR,1)]).';
    paramsR = maR;
    paramsR(good_ptsR) = opR(good_ptsR);


    %set opts.params_init for within fit_conjgrad
    tprintf('Finished iteration %d of %d, setting parameters\n',i,numel(nSD));
    opts.volume_paramsL = paramsL;
    opts.volume_paramsR = paramsR;
    error = cat(1,outputL(sum(good_ptsL,2)>0,10),outputR(sum(good_ptsR,2)>0,10));
    %Get rid of outliers
    error(error>500) = mean(error(error<=500));
    error(error==0) = mean(error(error~=0));
    opts.huberize = nSD(i).*std(error);
    tprintf('Setting huberization at %0.2f stdevs which is %0.2f\n',nSD(i),opts.huberize);
    fprintf('\n\n');

    %Plotting of parameters, can be commented out for production
    %Plot the huberization rate and the smoothed input parameters
%     figure(3);scatter(i,opts.huberize);hold on;title('Huberization');xlabel('iteration');ylabel('Max Error');
%     figure(4);plot(opts.volume_paramsL(:,[1:4,6:8]));title(sprintf('Left Parameters after smoothing at iteration %d',i))
%     print('-dpng',sprintf('./images/inputParamsL_%02d.png',i));
%     figure(5);plot(opts.volume_paramsR(:,[1:4,6:8]));title(sprintf('Right Parameters after smoothing at iteration %d',i))
%     print('-dpng',sprintf('./images/inputParamsR_%02d.png',i));
%     %Plot the error as a function of iteration
%     figure(6);plot(outputL(:,10),'Color',cmap(i,:));hold on;title('Left Error');ylim([0,30]);
%     figure(7);plot(outputR(:,10),'Color',cmap(i,:));hold on;title('Right Error');ylim([0,30]);
%     %Plot the actual parameters returned from fitting
%     figure(8);plot(outputL(:,[2:5,7:9]));title(sprintf('Left Parameters before smoothing at iteration %d',i))
%     print('-dpng',sprintf('./images/ParamsL_%02d.png',i));
%     figure(9);plot(outputR(:,[2:5,7:9]));title(sprintf('Right Parameters before smoothing at iteration %d',i))
%     print('-dpng',sprintf('./images/ParamsR_%02d.png',i));
%     drawnow;
end


tprintf('Loading original trees...\n');
load(treesFile);
tprintf('Combining left original results...\n')
Lr = zeros(size(outputL,1),4,nIters);
Rr = zeros(size(outputR,1),4,nIters);%title(sprintf('Right ON %0.1f to %0.4f',nSD(1),nSD(end)))
for i=1:nIters
    tprintf('\tWorking on iteration %d / %d\n', i, nIters);
    for iL = 1:size(outputL,1)
        Lr(iL,1,i)=allOpL(iL,1,i);
        Lr(iL,2,i)=Br1.predict(allOpL(iL,2:7,i));
        Lr(iL,3,i)=Br2.predict(allOpL(iL,2:7,i));
        Lr(iL,4,i)=allOpL(iL,10,i);
    end
end
tprintf('Combining right original results...\n')
for i=1:nIters
    tprintf('\tWorking on iteration %d / %d\n', i, nIters);
    for iR = 1:size(outputR,1)
        Rr(iR,1,i)=allOpR(iR,1,i);
        Rr(iR,2,i)=Br1.predict(allOpR(iR,2:7,i));
        Rr(iR,3,i)=Br2.predict(allOpR(iR,2:7,i));
        Rr(iR,4,i)=allOpR(iR,10,i);
    end
end

%% Save results
tprintf('Saving radii\n');
radiiFileL = [outDir filesep input_basename '_radiiL.txt'];
radiiFileR = [outDir filesep input_basename '_radiiR.txt'];
Lr2d = squeeze(Lr(:,:,end));
Rr2d = squeeze(Rr(:,:,end));
save(radiiFileL,'Lr2d','-ascii','-double');
save(radiiFileR,'Rr2d','-ascii','-double');

radiiFileL = [outDir filesep input_basename '_allRadiiL.mat'];
radiiFileR = [outDir filesep input_basename '_allRadiiR.mat'];
save(radiiFileL,'Lr');
save(radiiFileR,'Rr');

tprintf('Saving parameters\n');
paramsFileL = [outDir filesep input_basename '_paramsL.mat'];
paramsFileR = [outDir filesep input_basename '_paramsR.mat'];
save(paramsFileL,'allOpL');
save(paramsFileR,'allOpR');

tprintf('Saving centroids\n');
centroidsFileL = [outDir filesep input_basename '_CentroidsL.txt'];
centroidsFileR = [outDir filesep input_basename '_CentroidsR.txt'];
save(centroidsFileL,'centroidsL','-ascii','-double');
save(centroidsFileR,'centroidsR','-ascii','-double');

%% PDF
tprintf('Opening PDF\n');
pdf_path = [outDir filesep 'ON_sheath_report.pdf'];
guideFile = [mFilePath filesep 'PDF' filesep 'ON_Segmentation_template.fig'];
if ~exist(guideFile,'file')
    error('Could not find PDF template file');
end

tprintf('Setting text fields\n');
%XNAT INFO
XNATINFO=strcat('Project:',project,' / Subject:',subject,' / Session:',experiment');
%create the handle
f = openfig(guideFile);
handles = guihandles(f);
set(handles.text18,'FontSize',9);
set(handles.text18,'String',pdf_path);
set(handles.textXNAT,'FontSize',9);
set(handles.textXNAT,'String',XNATINFO);
set(handles.textinfo,'FontSize',9);
set(handles.textinfo,'String',sprintf('Trees used: %s', treesFile));


%%%%%%%%%%%%%%%%%%%%%%
%Page 1 - movement in sagittal and axial, final radii
%%%%%%%%%%%%%%%%%%%%%%
tprintf('Rendering page 1\n');

%%Left ON
pad = 5;

firstSlice = find( (validL ),1,'first');
lastSlice = find( (validL ), 1, 'last');
maxRL =ceil(max(max(centroidsL(:,2))));
minRL = floor(min(min(centroidsL(logical(validL),2))));
maxSI = ceil(max(max(centroidsL(:,1))));
minSI = floor(min(min(centroidsL(logical(validL),1))));

if maxRL>size(im,1)-pad, maxRL = size(im,1)-pad; end
if minRL<pad+1, minRL = pad+1;end
if maxSI>size(im,3)-pad, maxSI = size(im,3)-pad; end
if minSI<pad+1, minSI = pad+1;end

axes(handles.image0);
slice = im(minRL-pad:maxRL+pad,firstSlice-pad:lastSlice+pad,int16(mean(centroidsL(logical(validL),1))));
imagesc(slice,'Parent',handles.image0); title('Left ON Axial');hold on;
scatter(pad+1:sum(validL)+pad,rawCL(logical(validL),2)-minRL+pad,'Parent',handles.image0);
plot(pad+1:sum(validL)+pad,centroidsL(logical(validL),2)-minRL+pad,'Color','r');
quiver((pad+1:sum(validL)+pad)',centroidsL(logical(validL),2)-minRL+pad,...
    zeros(sum(validL),1),deltaCL(:,1),'r');
colormap gray
axis equal
axis off

%Sagittal view
axes(handles.image4);
slice = squeeze(im(int16(mean(centroidsL(logical(validL),2))),firstSlice-pad:lastSlice+pad,minSI-pad:maxSI+pad))';
imagesc(slice,'Parent',handles.image4); title('Left ON Sagittal');hold on;
scatter(pad+1:sum(validL)+pad,rawCL(logical(validL),1)-minSI+pad);
plot(pad+1:sum(validL)+pad,centroidsL(logical(validL),1)-minSI+pad,'Color','r');
quiver((pad+1:sum(validL)+pad)',centroidsL(logical(validL),1)-minSI+pad,...
    zeros(sum(validL),1),deltaCL(:,2),'r');
colormap gray
axis equal
axis off


%%Right ON
firstSlice = find( (validR ),1,'first');
lastSlice = find( (validR ), 1, 'last');
maxRL = ceil(max(max(centroidsR(:,2))));
minRL = floor(min(min(centroidsR(logical(validR),2))));
maxSI = ceil(max(max(centroidsR(:,1))));
minSI = floor(min(min(centroidsR(logical(validR),1))));

if maxRL>size(im,1)-pad, maxRL = size(im,1)-pad; end
if minRL<pad+1, minRL = pad+1;end
if maxSI>size(im,3)-pad, maxSI = size(im,3)-pad; end
if minSI<pad+1, minSI = pad+1;end

axes(handles.image1);
slice = im(minRL-pad:maxRL+pad,firstSlice-pad:lastSlice+pad,int16(mean(centroidsR(logical(validR),1))));
imagesc(slice,'Parent',handles.image1); title('Right ON Axial');hold on;
scatter(pad+1:sum(validR)+pad,rawCR(logical(validR),2)-minRL+pad,'Parent',handles.image1);
plot(pad+1:sum(validR)+pad,centroidsR(logical(validR),2)-minRL+pad,'Color','r');
quiver((pad+1:sum(validR)+pad)',centroidsR(logical(validR),2)-minRL+pad,...
    zeros(sum(validR),1),deltaCR(:,1),'r');
colormap gray
axis equal
axis off


% Sagittal View
axes(handles.image5);
slice = squeeze(im(int16(mean(centroidsR(logical(validR),2))),firstSlice-pad:lastSlice+pad,minSI-pad:maxSI+pad))';
imagesc(slice,'Parent',handles.image5); title('Right ON Sagittal');hold on;
scatter(pad+1:sum(validR)+pad,rawCR(logical(validR),1)-minSI+pad);
plot(pad+1:sum(validR)+pad,centroidsR(logical(validR),1)-minSI+pad,'Color','r');
quiver((pad+1:sum(validR)+pad)',centroidsR(logical(validR),1)-minSI+pad,...
    zeros(sum(validR),1),deltaCR(:,2),'r');
colormap gray
axis equal
axis off

%%Bottom row: Radius measurement results

axes(handles.image2);
plot(Lr(:,1,end),Lr(:,2,end),'Color','b','Parent',handles.image2);
hold on;
plot(Lr(:,1,end),Lr(:,3,end),'Color','r');
xlabel('Posterior Slice');ylabel('Radius');title('Left Optic Nerve');
axis([min(Lr(:,1,end)) max(Lr(:,1,end)) 0.4 4]);

axes(handles.image3);
plot(Rr(:,1,end),Rr(:,2,end),'Color','b','Parent',handles.image3);
hold on;
plot(Rr(:,1,end),Rr(:,3,end),'Color','r');
xlabel('Posterior Slice');ylabel('Radius');title('Right Optic Nerve');
axis([min(Rr(:,1,end)) max(Rr(:,1,end)) 0.4 4]);

% % Save the ps
tprintf('Exporting page 1\n');
% export_fig(pdf_path,'-pdf','-transparent',handles.figure1);
handle = handles.figure1;
% Make changing paper type possible
set(handle,'PaperType','<custom>');

% Set units to all be the same
set(handle,'PaperUnits','inches');
set(handle,'Units','inches');

% Set the page size and position to match the figure's dimensions
position = get(handle,'Position');
set(handle,'PaperPosition',[0,0,position(3:4)]);
set(handle,'PaperSize',position(3:4));
print('-dpsc2',pdf_path,'-r600',handle)
%%%%%%%%%%%%%%%
%Page 2 - parameters, error and renderings
%%%%%%%%%%%%%%%
tprintf('Rendering page 2\n');
f = openfig(guideFile);
handles = guihandles(f);
set(handles.text18,'FontSize',9);
set(handles.text18,'String',pdf_path);
set(handles.textXNAT,'FontSize',9);
set(handles.textXNAT,'String',XNATINFO);
set(handles.textinfo,'FontSize',9);
set(handles.textinfo,'String',sprintf('Trees used: %s', treesFile));
%%Left ON
% Parameters [slice,sx, sy, rho, s2, io, beta, ux, uy, error];
axes(handles.image0);cla;
plot(allOpL(:,[2:5,7],nIters));hold on;title('Final Left Parameters');
legend('\sigma_x','\sigma_y','\rho','\sigma_2','\beta','Location','Best','Orientation','horizontal');
set(gca,'XtickLabel','');
% Error
axes(handles.image4);cla;
imagesc(squeeze(allOpL(:,10,:)).');colormap jet;caxis([0 30]);
xlabel('Slice');ylabel('Iteration');
set(gca,'YDir','reverse');
h = title('\color{white}Left Error');
v = axis;
set(h,'Position',[v(2)*0.5 v(4)*.2 0]);
colorbar;

% 3D Rendering
ftemp = figure;
centroids3D = cat(1,centroidsL(logical(validL),2).',...
                    (firstL:firstL+sum(validL)-1),...
                    centroidsL(logical(validL),1).');
smoothedR = smooth(Lr(:,2,end),3);
[x,y,z] = tubeplot(centroids3D,smoothedR,100);
C = repmat([smoothedR(1);smoothedR;smoothedR(end)].',[size(x,1) 1]);
h = surf(y,x,z,C);axis equal;colormap jet;
% rotate(h,[0,1],90);
set(h,'EdgeColor','none')
view(-94,18);
material('dull');
lighting phong;
camlight headlight
axis vis3d;
axis off;
shading interp;
caxis([0.5 3.0]);
colorbar;
title('Left Inner Radius Rendering');

temp_png = 'leftON.png';
saveas(ftemp, temp_png);
axes(handles.image2);
img = imread(temp_png);
imshow(img);

%%Right ON
% Parameters [slice,sx, sy, rho, s2, io, beta, ux, uy, error];
axes(handles.image1);cla;
plot(allOpR(:,[2:5,7],nIters));hold on;title('Final Right Parameters');
legend('\sigma_x','\sigma_y','\rho','\sigma_2','\beta','Location','Best','Orientation','horizontal');
set(gca,'XtickLabel','');
% Error
axes(handles.image5);cla;
imagesc(squeeze(allOpR(:,10,:)).');colormap jet;caxis([0 30]);
xlabel('Slice');ylabel('Iteration');
set(gca,'YDir','reverse');
h = title('\color{white}Right Error');
v = axis;
set(h,'Position',[v(2)*0.5 v(4)*.2 0]);
colorbar;

% 3D Rendering
ftemp = figure;
centroids3D = cat(1,centroidsR(logical(validR),2).',...
                    (firstR:firstR+sum(validR)-1),...
                    centroidsR(logical(validR),1).');
smoothedR = smooth(Rr(:,2,end),3);
[x,y,z] = tubeplot(centroids3D,smoothedR,100);
C = repmat([smoothedR(1);smoothedR;smoothedR(end)].',[size(x,1) 1]);
h = surf(y,x,z,C);axis equal;
colormap jet;
set(h,'EdgeColor','none');
view(-94,18);
% rotate(h,[0,-1],90);
%rotate(h,[1,0],180); %flip L/R so globe is medial for both
material('dull');
lighting phong;
camlight headlight
axis vis3d;
axis off;
shading interp;
caxis([0.5 3.0]);
colorbar;
title('Right Inner Radius Rendering');

temp_png = 'rightON.png';
saveas(ftemp, temp_png);
axes(handles.image3);
img = imread(temp_png);
imshow(img);

% % Save the ps
tprintf('Saving page 2\n');
% export_fig(pdf_path,'-pdf','-append','-transparent',handles.figure1);

handle = handles.figure1;
% Make changing paper type possible
set(handle,'PaperType','<custom>');

% Set units to all be the same
set(handle,'PaperUnits','inches');
set(handle,'Units','inches');

% Set the page size and position to match the figure's dimensions
position = get(handle,'Position');
set(handle,'PaperPosition',[0,0,position(3:4)]);
set(handle,'PaperSize',position(3:4));
print('-dpsc2','-append',temp_ps_path,'-r150',handle)

cmmd = ['ps2pdf -dPDFSETTINGS=/prepress ' temp_ps_path ' ' pdf_path];
[status,msg]=system(cmmd);
if status~=0 
    fprintf('\n Could not cleanly create pdf file from ps.\n');
    disp(msg);
end

tprintf('function ON_CONJGRAD_3D_v2 COMPLETE, exiting\n');
end











