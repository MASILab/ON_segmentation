function [ftol, gradtol, iter_max, normalize, keep_trying,save_gif,gif_filename,display, params] = check_options(im,sz,gradient_function,options)

% default initializations, need for: {sx,sy,r,s1,s2,mx,my,io,b,ux,uy}
% I used rob's defaults
d_sxi=2;
d_syi=2;
d_ri=eps;
d_s2i=0.6;
d_ioi=1; % not used
d_bi=log(.5);
d_uxi=0;
d_uyi=0;

% default termination settings
d_ftol = 10e-12;
d_gradtol = 10e-6;
d_iter_max = 100;

% other
d_display  = true;
d_normalize = true;
d_keep_trying = 0;
d_save_gif=false;
d_gif_filename='';

% put defaults in there
ftol = d_ftol;
gradtol = d_gradtol;
normalize = d_normalize;
iter_max = d_iter_max;
params = 'needed';
keep_trying = d_keep_trying;
save_gif=d_save_gif;
gif_filename=d_gif_filename;
display = d_display;

% if argument is completely missing,
if isempty(options);
    fprintf('No options specified for model_spdesc: using all defaults.\n\n');
    
    % if its a vector of the correct length, then initialization params must be the
    % thing given
elseif isa(options, 'numeric') && (length(options)>=8 || length(options) <=9)
    params = options(:);
    fprintf(['No options specified for model_spdesc: using defaults for '...
        'all but param initialization.\n\n']);
    
    % parse if it's a struct
elseif isa(options,'struct');
    if isfield(options, 'ftol');
        ftol = options.ftol;
        options = rmfield(options,'ftol');
    end
    if isfield(options, 'gradtol');
        gradtol = options.gradtol;
        options = rmfield(options,'gradtol');
    end
    if isfield(options, 'iter_max');
        iter_max = options.iter_max;
        options = rmfield(options,'iter_max');
    end
    if isfield(options,'params_init');
        params = options.params_init(:);
        options = rmfield(options,'params_init');
    end
    if isfield(options,'normalize')
        normalize = options.normalize;
        options = rmfield(options,'normalize');
    end
    if isfield(options,'keep_trying')
        keep_trying = options.keep_trying;
        options = rmfield(options,'keep_trying');
    end
    if isfield(options,'save_gif')
        save_gif=options.save_gif;
        options=rmfield(options,'save_gif');
        gif_filename=[pwd,filesep,'conjgrad.gif'];
    end
    if isfield(options,'gif_filename')
        gif_filename=options.gif_filename;
        options=rmfield(options,'gif_filename');
    end
    if isfield(options,'display')
        display = options.display;
        options=rmfield(options,'display');
    end
%    fields = fieldnames(options);
%    if ~isempty(fields)
%        warning_str = 'At least one field in the options struct was not recognized:\n';
%        for i = 1:length(fields)
%            warning_str = [warning_str,['\t' fields{i} '\n']];
%        end
%        warning('model_stpdesc:options',warning_str);
%    end
    
    % if its not a struct or the correct-length vector, i don't knwo what it is
else
    error('model_stpdesc:options','options argument not in recognizable form');
end


% try to testimate a good start of all params
if isa(params,'char') && strcmp(params,'needed')
    
    % try to estimate good start for sx,sy by looking for peaks
    imnorm=(im-min(im(:)))./max(im(:)-min(im(:)));
    xslice = imnorm(floor(sz(1)/2),:);
    yslice = imnorm(:,floor(sz(1)/2));
    [xpks,xlocs] = findpeaks(xslice,'NPEAKS',2,'SORTSTR','descend');
    [ypks,ylocs] = findpeaks(yslice,'NPEAKS',2,'SORTSTR','descend');
    
    if length(xlocs)==2&&length(ylocs)==2
        sxi=abs(xlocs(2)-xlocs(1))/2;
        syi=abs(ylocs(2)-ylocs(1))/2;
    else
        sxi=d_sxi;
        syi=d_syi;
    end
    
    % try a similar approach for rho
    xymslice=diag(im);
    xyslice = diag(fliplr(im));
    [~,xylocs]   = findpeaks(xyslice,'NPEAKS',2,'SORTSTR','descend');
    [~,xymlocs] = findpeaks(xymslice,'NPEAKS',2,'SORTSTR','descend');
    if length(xylocs)==2 && length(xymlocs)==2
        xy = abs(xylocs(2)-xylocs(1))/2;
        xym= abs(xymlocs(2)-xymlocs(1))/2;
        ri = xym-xy+eps;
    else
        ri=d_ri;
        warning('model_stpdesc:rho_init', 'rho could not be initialized')
    end
    
    
    
    % defaults for {s2,b,ux,uy} just set to nice values (for now)
    s2i=d_s2i;
    bi=d_bi;
    uxi=d_uxi;
    uyi=d_uyi;
    
    
 if mod(sz(1),2)==0
[x,y] = ...
    meshgrid(-floor(sz(1)/2)+0.5:floor((sz(1))/2),-floor(sz(2)/2)+0.5:floor((sz(2))/2));
else
    [x,y] = ...
    meshgrid(-floor(sz(1)/2):floor((sz(1))/2),-floor(sz(2)/2):floor((sz(2))/2));
end
    params = [sxi; syi; ri; s2i; 1; bi; uxi; uyi];
    [~,model,~]=gradient_function(im(:),x(:),y(:),params);

    % calculate initial io
    ioit=mean([xpks(:);ypks(:)]);  %target value
    mainPeak = max(model(:)); %Get the height now
    ioi = ioit/mainPeak;%Get to the target height
    
    % arrange into vector
    params = [sxi; syi; ri; s2i; ioi; bi; uxi; uyi];
end
end
