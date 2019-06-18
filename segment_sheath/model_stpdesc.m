function [fit_model,params,f_final] = model_stpdesc(im,gradient_function,varargin)
% Syntax: [fit_model,params,f] = model_stpdesc(im,gradient_function)
%         [fit_model,params,f] = model_stpdesc(im,gradient_function,options)
%         [fit_model,params,f] = model_stpdesc(im,gradient_function,params_init)
%
% Input:
%   im - the image that the model will be fit to. Must be square. Can be a
%     MATLAB matrix or a file name string.
%   gradient_function - handle to gradient function used (e.g.,
%     @model_gradient5). This model function must be of a certain form.
%   [optional] options - struct that can contain the fields:
%       ftol - function difference tolerance (for convergence) [default: 10e-12]
%       gradtol - tolerance for decreaseing gradient (for convergence) [default: 10e-6]
%       iter_max - max iterations [default: 100]
%       params_init - a vector of initial parameters. must be correct length
%           [default: decent starting position found heuristically]
%       keep_trying - an integer that, if set >0, will cause the
%                algorithm to "keep trying" if a convergence criteria is not reached.
%       save_gif: set to true to save a gif of the transformation
%       gif_filename: allows you to specify a filename for the gif, if
%               omitted it will be saved in the current dir as conjgrad.gif
%       display : boolean of whether or not to show the figure display
%       (default true)
%
%   [optional] params_init - can just input params instead of options struct if
%       you so desire. all tolerances will be set to default
%
%       Definitions:
%       function and gradient tolerance are the convergence criteria
%       itertation count, NaN detection, and function increase are
%       divergence criteria.


%make sure we have our necessary functions
% pathCell = regexp(path, pathsep, 'split');
% onPath = any(strcmpi([pwd,'/helper_functions/'], pathCell));
% 
% if ~onPath
%     addpath(genpath([pwd,'/helper_functions/']));
%     addpath(genpath([pwd,'/model_gradients/']));
% end

% some arg parsing
if nargin<2
    error('not enough args');
end
if ~isa(gradient_function,'function_handle');
    error('model:stpdesc', 'gradient function arguement must be a function handle');
end

% accout for possible missing 3rd arg
if nargin<3;
    options=[];  % empty
else
    options = varargin{1};
    opts_save=options;
end


% deal with input image
% if its a char, assume its a path and load it
if isa(im,'char')
    % read in file
    im = double(imread(im));
end

% check size
sz = size(im);
if ~ismatrix(im)
    error('must be a 2D image')
end

% parse options struct, setting to default if necessary
[ftol, gradtol, iter_max, normalize, keep_trying, save_gif,gif_filename,display,params] = check_options(im,sz,gradient_function,options);


% if sz(1)~=sz(2), error('Must be a square image');end % why must it be square?
if any(sz<2)
    warning('you''ve input an image that is only size=1 in one dimension (i.e., a vector');
end

% normalize to 1
if normalize
    im = im-min(im(:));
    im = im./max(im(:));
end

% create x,y ndgrid (this line handles both even and odd)
% [xl,yl] = meshgrid(linspace(-sz(1)/2,sz(1)/2,sz(1)),linspace(-sz(2)/2,sz(2)/2,sz(2)));
if mod(sz(1),2)==0
    [x,y] = ...
        meshgrid(-floor(sz(1)/2)+0.5:floor((sz(1))/2),-floor(sz(2)/2)+0.5:floor((sz(2))/2));
else
    [x,y] = ...
        meshgrid(-floor(sz(1)/2):floor((sz(1))/2),-floor(sz(2)/2):floor((sz(2))/2));
end

% make everything a vector
im = im(:);
x = x(:);
y = y(:);

% first iteration, need to get some initial info
k=1; % k really should be 0, but matlab starts at 1
best_params = params;

% initial function eval
[g,model,f(k)]=gradient_function(im,x,y,params);
if isfield(options,'huberize')
    if abs(f(k))>options.huberize
        %If we're outside the model to begin with we won't get anywhere
        %so just exit
        fit_model = model;
        fit_model = reshape(fit_model,sz);
        f_final = f(k);
        tprintf('Model initializated outside of huberization. Exiting\n');
        return
    end
end
tprintf('Iteration %i: |g|= %f, f=%f\n',k-1,norm(g),f(k));
if display
    fig = gcf; clf; plot_fig(im,model,sz,f(k),false);
end
if save_gif,save_gif_image(reshape(im,sz),reshape(model,sz),gif_filename,f(k),k,false);end


% 1st real iteration
k=2; % iteration variable
% find search direction
p{k}=-g; % negative gradient direciotn
% take tiny step (cant initialize linesearch w/ no previous iteration)
a(k) = 0.0001;
params = params + a(k)*p{k};

% evaluate current model
[g,~,f(k)] = gradient_function(im,x,y,params);
if isfield(options,'huberize')
    if abs(f(k))>options.huberize
        g=0;
        f(k) = options.huberize;
    end
end
if f(k)<f(k-1)
    best_params = params;
end

% break conditions initializiation
increased_once = false;
isnan_once=false;
success = false; % flag indicates convergence (convergence is good)
num_cg_directions_since_reset = 0;
bad_things_happened = true; % to make sure it does stp desc the first time
while 1
    
    % find search direction
    % steepest desc
    if num_cg_directions_since_reset == length(params) || bad_things_happened
        p{k}=-g;
        num_cg_directions_since_reset = 0;
    else % conj direction
        p{k} = -g + g'*(g-gkminus1)/(gkminus1'*gkminus1)*p{k-1};
        num_cg_directions_since_reset = num_cg_directions_since_reset + 1;
    end
    
    % linesearch to get step length
    % pass it current position, past and present directions & step-lengths
    [a(k), bad_things_happened] = linesearch(im,x,y,params,p{end},f(k-1),gradient_function);
    %     if bad_things_happened
    %         keyboard;
    %     end
    
    % take step
    last_params=params;
    params = params + a(k)*p{k};
    
    % check/enforce constraints
    %[sxi; syi; ri; s2i; ioi; bi; uxi; uyi];
    params = enforce_contraints(params);
    
    % update counter
    k = k+1;
    gkminus1 = g;
    
    % evalute current model
    [g,model,f(k)] = gradient_function(im,x,y,params);
    if isfield(options,'huberize')
        if abs(f(k))>options.huberize
            g=0;
            f(k) = options.huberize;
        end
    end
    
    
    % print and display output
    if display
        tprintf('Iteration %i: |g|= %f, f=%f, delta_f=%f\n',k-1,norm(g),f(k),f(k)-f(k-1));
        print_params(params);
        figure(fig);
        plot_fig(im,model,sz,f(k),false);
    end
    if f(k)<f(k-1)
        best_params = params;
    end
    
    % termination criteria
    
    % max iteration (divergence criteria)
    if k>=iter_max
        warning('stpdesc:maxiter','Max iterations reached');
        break
    end
    % 2 consecutive iterations of function increase (divergence criteria)
    if f(k)>f(k-1)
        if increased_once
            params = safe_params;
            warning('stpdesc:funcinc',...
                'Function increase detected - terminating and using old (valid) params');
            break
        end
        increased_once = true;
        safe_params = last_params;
    end
    % params have gone to NaN (divergence criteria)
    if isnan(f(k)) || isnan(norm(g))
        if isnan_once
            params=safe_params;
            warning('stpdesc:funcnan',...
                'Function has gone NaN - terminating and using old (valid) params');
            break;
        end
        isnan_once=true;
        safe_params=last_params;
    end
    % non-changing function value (convergence criteria)
    if abs(f(k)-f(k-1))<ftol;
        tprintf('Function values non-decreasing to specified tolerance\n');
        success = true;
        break
    end
    % sufficiently small gradient magnitude indicates distance to minima is small
    % (convergence criteria)
    if norm(g)<gradtol
        tprintf('Gradient approximately zero to specified tolerance\n');
        success = true;
        break
    end
    
end


%% output final model using latest params
[g_final,fit_model,f_final] = gradient_function(im,x,y,params);
if display
    plot_fig(im,fit_model,sz,f_final,false);
end
fit_model = reshape(fit_model,sz);

% final output
tprintf('Final Model: |g|= %f, f=%f\n',norm(g_final),f_final);
if display
    print_params(params);
end
% keyboard
% alternate output
if any(f<f_final)
    [~,model_best,f_best] = gradient_function(im,x,y,best_params);
    
    tprintf('\n\nA better result was found, other than the final output.\n');
    tprintf('The best result was: f=%f\n',f_best)
    if display
        print_params(best_params);
        figure;
        plot_fig(im,model_best,sz,f(k),false);
    end
end

% keep trying if not successful and user wants to try
if ~success && keep_trying>0;
    if display
        tprintf('\n\n');
        tprintf('--------------------------------------------------------------------------- \n\n');
        tprintf('Convergence not detected. Going to "keep trying," up to %i more time(s)\n\n',keep_trying);
        tprintf('--------------------------------------------------------------------------- \n\n');
    end
    opts=opts_save;
    opts.display=display;
    opts.params_init = best_params;
    opts.normalize = false;
    opts.ftol = ftol;
    opts.gradtol = gradtol;
    opts.iter_max = iter_max;
    opts.keep_trying = keep_trying-1;
    
    
    [fit_model,params,f_final] = model_stpdesc(reshape(im,sz),gradient_function,opts);
end
end
