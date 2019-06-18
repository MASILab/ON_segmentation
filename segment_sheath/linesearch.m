function [c,varargout] = linesearch(Im,x,y,params,p,fkminus1,gradient_function)
% cubic interpolation linesearch

% intializations
enforce_stpdesc_next_step = false; % a flag that is triggered if things aren't going well.

% get current gradient and function eval
[grad_at_a,~,fun_at_a]=gradient_function(Im,x,y,params);

% check and mask sure it's a descnet direction
% very bad if this is an ascent direction!
if p'*grad_at_a > 0
    warning('stpdesc:linesearch:nondescent',...
        ['Directional derivative at a > 0! \n'...
        'DID NOT TAKE A STEP, next step will be stp desc!']);
    c=0;
    enforce_stpdesc_next_step = true;
    varargout{1} = enforce_stpdesc_next_step;
    return;
elseif abs(p'*grad_at_a) < eps
    warning('stpdesc:linesearch:zerostep',...
            ['Step is approximately zero\n' ...
             'meaning step will be rank deficient\n' ...
            'DID NOT TAKE A STEP, next step will be stp desc!']);
    c = 0;
    enforce_stpdesc_next_step = true;
    varargout{1} = enforce_stpdesc_next_step;
    return;
end

% estimate b, the far side of interval, from formula
% going to use the a,b,c notation from class;
fk = fun_at_a;
a = 0;
b = 2*(fk-fkminus1)/(p'*grad_at_a);

% get gradient at b and sanity check b
% just take a small step if necessary
[grad_at_b,~,fun_at_b]=gradient_function(Im,x,y,params+b*p);
while ~isreal(grad_at_b) || ~isreal(fun_at_b);
    % sort of trust regiony behavior,
    % take smaller and smaller steps until its not longer complex
    b = 1/4*b;
    [grad_at_b,~,fun_at_b]=gradient_function(Im,x,y,params+b*p);
end

% very bad situation (hasn't occured often in practice)
if b==0;
    c=a;
    warning('stpdesc:linesearch:bequalszero',...
        ['b == 0! \n'...
        'DID NOT TAKE A STEP, next step will be stp desc!']);
    enforce_stpdesc_next_step = true;
    varargout{1} = enforce_stpdesc_next_step;
    return;
end

% bad situation, expect p'grad_at_b to be >0 (positive slope indicates that
% minimizer is between a & b
if  p'*grad_at_b<0
%     warning('stpdesc:linesearch:bracketinit','bracket init assumption wrong, taking small step');

    % make sure b is a descent direction
    if fun_at_b < fun_at_a
        c = b;

    else % f(b) is larger than f(a)! bad!
        c = a;
        warning('stpdesc:linesearch:nondescent',...
            'DID NOT TAKE A STEP, next step will be stp desc!');
        enforce_stpdesc_next_step = true;
    end
    varargout{1} = enforce_stpdesc_next_step;
    return;
end
initial_size = b;

% do first iteration
% get directional derivatives (scalars)
dirdiv_at_a = grad_at_a'*p;
dirdiv_at_b = grad_at_b'*p;
% cubic fitting
z = 3*(fun_at_a-fun_at_b)/(b-a) + dirdiv_at_a + dirdiv_at_b;
w = sqrt(z^2-dirdiv_at_a*dirdiv_at_b);
c = a + (b-a)*(z+w-dirdiv_at_a)/(dirdiv_at_b-dirdiv_at_a+2*w);
% sanity check - if necessary, do bisection
if c<=a || c>=b
    warning('stpdesc:linesearch:cubicfitfailed',...
        'Cubic fitting result is nonsense. This is bad. NOT TAKING A STEP, next step will be stp desc!');
%     plot_linesearch(b,gradient_function,Im,x,y,params,p)
    c = a; % dont step
    enforce_stpdesc_next_step = true;
end

% now start loop
cprev = inf;k=0; % initializtion for termination criteria
while ~enforce_stpdesc_next_step % if this is true, something bad is going on
    % pick new interval
    [grad_at_c,~,~]=gradient_function(Im,x,y,params+c*p);
    dirdiv_at_c = p'*grad_at_c;

    if dirdiv_at_c<=0 % still going down, pick right interval
        a=c;
    else
        b=c;
    end

    % get directional derivatives (scalars)
    dirdiv_at_a = grad_at_a'*p;
    dirdiv_at_b = grad_at_b'*p;

    % cubic fitting with bisection every 5
    if mod(k,5)==0; %cubic
        z = 3*(fun_at_a-fun_at_b)/(b-a) + dirdiv_at_a + dirdiv_at_b;
        w = sqrt(z^2-dirdiv_at_a*dirdiv_at_b);
        c = a + (b-a)*(z+w-dirdiv_at_a)/(dirdiv_at_b-dirdiv_at_a+2*w);
    else % bisection
        c = .5* (a+b);
    end

    % sanity check - if necessary, do bisection
    if c<=a || c>=b
        warning('stpdesc:linesearch:cubicfitfailed',...
            'Cubic fitting result is nonsense. This is bad. NOT TAKING A STEP, next step will be stp desc!');
        %     plot_linesearch(b,gradient_function,Im,x,y,params,p)
        c = a; % dont step
        enforce_stpdesc_next_step = true;
        break;
    end

    % termination conditions
    if (abs(c-cprev)<10e-8*initial_size) || (norm(dirdiv_at_c)<10e-9)
        break;
    end
    if k>25;
        warning('stpdesc:linesearch:maxits','Max its reached in linesearch');
        break;
    end
    k=k+1;
    cprev=c;
end

% set variable lenght output
if nargout>1
    varargout{1} = enforce_stpdesc_next_step;
end





% for debug
function plot_linesearch(b,gradient_function,Im,x,y,params,p)
keyboard;
sweep =0:2*b/250:b;
fun = zeros(size(sweep)); grad = zeros(size(sweep));
for i=1:length(sweep);
    [g,~,f]=gradient_function(Im,x,y,params+sweep(i)*p);
    fun(i) = f; grad(i) = g'*p;
end;
figure; subplot(2,1,1);
plot(sweep,fun); title('f - is there a minima?');
subplot(2,1,2); plot(sweep,grad,'r'); title('g - look for zero crossing'); grid on;




% old idea. moved and commented out, but it might still be useful
% % get gradient at b and make sure gradient is positive
% [grad_at_b,~,fun_at_b]=gradient_function(Im,x,y,params+b*p);
% while p'*grad_at_b<0
%     b=b*2;
%     [grad_at_b,~,fun_at_b]=gradient_function(Im,x,y,params+b*p);
%     disp('.');
% end
