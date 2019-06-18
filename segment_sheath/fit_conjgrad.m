function [outputL,outputR] = fit_conjgrad(im,centroidsL,centroidsR,...
    validL,validR,support,opts)
%FIT_CONJGRAD - fit the ON on an already loaded image file
%
% Syntax:  [outputL,outputR,Lr,Rr] = fit_conjgrad(im,centroidsL,centroidsR,...
%    validL,validR,support,treesFile,outFileL,outFileR,opts)
%
% Inputs:
%    im - The image to be fit
%    centroidsL - vector of centroids for the left ON
%    centroidsR - vector of centroids for the right ON
%    validL     - boolean vector of slices which contain left ON
%    validR     - boolean vector of slices which contain right ON
%    support    - The support (in voxels) to use for the model
%    outDir     - Directory to save the results
%    opts       - opts structure to be passed to model_stpdesc
%       - volume_paramsR - additional option to specifiy starting
%       parameters for an entire volume. Must be the same length as Rr (ie
%       only specify parameters for each slice with ON, not for all slices
%       in the volume)
%       - volume_paramsL - see above
%       - huberize - value to huberize the error function (cutoff)
%
% Outputs:
%    outputL - Nx10 matrix of output values for the left ON as:
%       [slice,sx, sy, rho, s2, io, beta, ux, uy, error];
%    outputR - results for the right ON
%
% Other m-files required: model_stpdesc
% Subfunctions: none
% MAT-files required: none
%
% See also: ON_conjgrad, model_stpdesc
%
% Author:  harrigr
% Date:    09-Sep-2015 13:37:53
% Version: 1.0
% Changelog:
%
% 09-Sep-2015 13:37:53 - initial creation
%
%------------- BEGIN CODE --------------

%% Fit the ON model
nSlices = size(im,2);
outputR=zeros(sum(validR),10);
outputL=zeros(sum(validL),10);
rInd=1;
lInd=1;
for slice=1:nSlices
    
    if validL(slice)
        tprintf('Found left ON labels in slice %d\n',slice);
        % pull out the patch
        mu= squeeze(centroidsL(slice,:));
        x = mu(1)-support:1:mu(1)+support; %// x axis
        y = mu(2)-support:1:mu(2)+support;
        [X, Y] = meshgrid(x,y); %// all combinations of x, y
        patch = interp2((squeeze(im(:,slice,:))),X,Y);
        
        %Check for parameters
        if isfield(opts,'volume_paramsL')
            opts.params_init = opts.volume_paramsL(lInd,:);
            if opts.display
                tprintf('\tUsing initialization parameters for the left ON\n');
                print_params(opts.params_init);
            end
        end
        
        % now do conjugate gradient descent
        [~, params,f] = model_stpdesc(patch,@model_gradient7,opts);
        outputL(lInd,:)=[slice;params;f]';        
        lInd=lInd+1;
        
        tprintf('Converged to a solution for left slice %d.\n',slice);
    end
    %% Right
    if validR(slice)
        % pull out the patch
        mu= squeeze(centroidsR(slice,:));
        x = mu(1)-support:1:mu(1)+support; %// x axis
        y = mu(2)-support:1:mu(2)+support;
        [X, Y] = meshgrid(x,y); %// all combinations of x, y
        patch = interp2((squeeze(im(:,slice,:))),X,Y);
        
        %Check for parameters
        if isfield(opts,'volume_paramsR')
            opts.params_init = opts.volume_paramsR(rInd,:);
            if opts.display
                tprintf('\tUsing initialization parameters for the right ON\n');
                print_params(opts.params_init);
            end
        end
        
        % now do conjugate gradient descent
        [~, params,f] = model_stpdesc(patch,@model_gradient7,opts);
        outputR(rInd,:)=[slice;params;f]';        
        rInd=rInd+1;
        
        tprintf('Converged to a solution for right slice %d.\n',slice);
    end
    
end

%------------- END OF CODE --------------