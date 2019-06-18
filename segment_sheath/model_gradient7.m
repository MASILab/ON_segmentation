function [grad,model,f] = model_gradient7(Im,x,y,params)
% Syntax: [grad,model,f] = model_gradient5(Im,x,y,params)
% Input: 
%   Im - vectorized target image
%   x - meshgrid or ndgrid created x-locations (vectorized like Im)
%   y - similar to input parameter x. 
%   params - 8x1 vector of parameters to generate the model 
%       [sx, sy, r, s2, io, b, ux, uy]
% Output: 
%   grad - an 8x1 vector for gradient at that point
%   model - a vector with the same numel as the image, should be reshaped into
%       image
%   f - function value (error value)

% check nargs
narginchk(4,4);
% if nargin<4 
%     error('incorrect number of input args');
% end

% data to be input as model_gradient(im,x,y,params)
sx=params(1);
sy=params(2);
r=params(3);
% s1=params(4);
s2=params(4);
io=params(5);
b=params(6);
ux=params(7);
uy=params(8);

% make sure elementst that might be matricies are indeed vectorized
if ~isequal(size(Im), size(x),size(y),[numel(Im) 1])
    error('Im,x,y inputs should be the same size and they should be vectors');
end

% Construct gradient:
% the function we are trying to min is:
% SUM((Im-f).^2), so that partial is going to be 
% SUM((Im-f).* -df.../d[..] )where .. is each element in the set 
%  {sx,sy,r,s1,s2,mx,my,io,b,ux,uy}

%% partials w.r.t each element

% zero_vect = zeros(size(x));
% part_sigr = part_sigr;


part_sx = io.*(-(1./(exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*sx.^2.*sy))) + ...
    exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2)))./...
    (2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*s2.^2.*sx.^2.*sy) - (-((2.*(-ux + x).^2)./sx.^3) + (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.^2.*sy))./...
    (exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*sx.*sy)) + ...
    (exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (-((2.*(-ux + x).^2)./(s2.^2.*sx.^3)) + (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.^2.*sy)))./(4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*s2.^2.*sx.*sy));

part_sy = io.*(-(1./(exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*sx.*sy.^2))) + ...
    exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2)))./...
    (2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*s2.^2.*sx.*sy.^2) - ((2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy.^2) - (2.*(-uy + y).^2)./sy.^3)./...
    (exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*sx.*sy)) + ...
    (exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    ((2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy.^2) - (2.*(-uy + y).^2)./(s2.^2.*sy.^3)))./(4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*s2.^2.*sx.*sy));

part_r = io.*((exp(-r - ((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).* ...
    (-1 + 2./(1 + exp(-r))))./((1 + exp(-r)).^2.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*sx.*sy) -  ...
    (exp(b - r - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./ ...
    (2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*(-1 + 2./(1 + exp(-r))))./((1 + exp(-r)).^2.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*s2.^2.*sx.*sy) +  ...
    ((2.*(-ux + x).*(-uy + y))./(exp(r).*((1 + exp(-r)).^2.*(1 - (-1 + 2./(1 + exp(-r))).^2).*sx.*sy)) -  ...
    (2.*(-1 + 2./(1 + exp(-r))).*((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2))./ ...
    (exp(r).*((1 + exp(-r)).^2.*(1 - (-1 + 2./(1 + exp(-r))).^2).^2)))./(exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./ ...
    (2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*(2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*sx.*sy)) -  ...
    (exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).* ...
    ((2.*(-ux + x).*(-uy + y))./(exp(r).*((1 + exp(-r)).^2.*(1 - (-1 + 2./(1 + exp(-r))).^2).*s2.^2.*sx.*sy)) -  ...
    (2.*(-1 + 2./(1 + exp(-r))).*((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2)))./ ...
    (exp(r).*((1 + exp(-r)).^2.*(1 - (-1 + 2./(1 + exp(-r))).^2).^2))))./(2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*s2.^2.*sx.*sy));

% part_s1 = zero_vect;

part_s2 = io.*(exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./ ...
    (2.*(1 - (-1 + 2./(1 + exp(-r))).^2)))./(sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*s2.^3.*sx.*sy) + ...
    (exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (-((2.*(-ux + x).^2)./(s2.^3.*sx.^2)) + (4.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^3.*sx.*sy) - (2.*(-uy + y).^2)./(s2.^3.*sy.^2)))./...
    (4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*s2.^2.*sx.*sy));

part_io = 1./(exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*sx.*sy)) -...
    exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2)))./...
    (2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*s2.^2.*sx.*sy);

part_b = -((exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    io)./(2.*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2).*pi.*s2.^2.*sx.*sy));

part_ux = io.*(-((-((2.*(-ux + x))./sx.^2) + (2.*(-1 + 2./(1 + exp(-r))).*(-uy + y))./(sx.*sy))./...
    (exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*sx.*sy))) +...
    (exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (-((2.*(-ux + x))./(s2.^2.*sx.^2)) + (2.*(-1 + 2./(1 + exp(-r))).*(-uy + y))./(s2.^2.*sx.*sy)))./(4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*s2.^2.*sx.*sy));

part_uy = io.*(-(((2.*(-1 + 2./(1 + exp(-r))).*(-ux + x))./(sx.*sy) - (2.*(-uy + y))./sy.^2)./...
    (exp(((-ux + x).^2./sx.^2 - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx.*sy) + (-uy + y).^2./sy.^2)./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    (4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*sx.*sy))) +...
    (exp(b - ((-ux + x).^2./(s2.^2.*sx.^2) - (2.*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2.*sx.*sy) + (-uy + y).^2./(s2.^2.*sy.^2))./(2.*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
    ((2.*(-1 + 2./(1 + exp(-r))).*(-ux + x))./(s2.^2.*sx.*sy) - (2.*(-uy + y))./(s2.^2.*sy.^2)))./(4.*(1 - (-1 + 2./(1 + exp(-r))).^2).^(3./2).*pi.*s2.^2.*sx.*sy));

% now that we've calculated all the partials, we'll prepend the (If-f) term.

% We need the function value at each pixel:
model =  io*(1./(exp(((-ux + x).^2./sx.^2 - (2*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(sx*sy) + (-uy + y).^2./sy.^2)./(2*(1 - (-1 + 2./(1 + exp(-r))).^2))).*...
     (2*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2)*pi*sx*sy)) - ...
   exp(b - ((-ux + x).^2./(s2.^2*sx.^2) - (2*(-1 + 2./(1 + exp(-r))).*(-ux + x).*(-uy + y))./(s2.^2*sx*sy) + (-uy + y).^2./(s2.^2*sy.^2))./(2*(1 - (-1 + 2./(1 + exp(-r))).^2)))./...
    (2*sqrt(1 - (-1 + 2./(1 + exp(-r))).^2)*pi*s2.^2*sx*sy));

% and multiply that by each partial (note addition of negative sign).
grad = -[part_sx, part_sy, part_r, part_s2, part_io, part_b, part_ux, part_uy];
grad = repmat(Im-model, [1,size(grad,2)]) .* grad; % replicate the (Im-model) term
% So now, the final gradient is:
grad = sum(grad,1)'; % transposed to make it a vector;

% function value (error) is:
f = sum((Im-model).^2);





% % code that was replaced - i would suggest keeping that very verbose code
% somewhwere
% and comparing it to these shorter versions to ensure that no error../typos are
% introduced
% 
% xterm = ((x-ux)/sx).^2;
% yterm = ((y-uy)/sy).^2;
% jointterm = 2.*r.*(x-ux).*(y-uy)/(sx.*sy);
% exp(on=xterm+yterm-jointterm;
% exp(term1= exp((-1/(2.*(1-r.^2)).*( xterm + yterm - jointterm ) );
% exp(term2= exp((-1/(2.*s2.^2.*(1-r.^2)).*( xterm + yterm - jointterm ) );
% common_denom = 2.*pi.*sqrt(1-r.^2).*sx.*sy;
% N1 = exp(term1.../(common_denom);
% N2 = b.*exp(term2.../(common_denom.*s2.^2);
% Ihat = N1-N2;
% 
% 
% %% here are all of the partial terms
% 
% part_sx = -Ihat.*(1../sx + (xterm + jointterm)../(sx.*(1-r)));
% 
% part_sy = -Ihat.*(1../sy + (yterm + jointterm)../(sy.*(1-r)));
% 
% % part_r = -Ihat.*(r.../(1-r.^2)) - ...
% %     (jointterm.../(2.*r.^2)-2.*r.*exp(on).*N1 + ...
% %     b.*(jointterm.../(2.*r.^2.*s2.^2) - 2.*r.*exp(on.../s2.^2).*N2;
% 
% part_r = io.*(r.../(exp((((-ux + x).^2.../sx.^2 - (2.*r.*(-ux + x).*(-uy + y)).../(sx.*sy) + (-uy + y).^2.../sy.^2).../(2.*(1 - r.^2))).*(2.*pi.*(1 - r.^2).^(3.../2).*sx.*sy)) -...
%     (b.*r).../(exp((((-ux + x).^2.../sx.^2 - (2.*r.*(-ux + x).*(-uy + y)).../(sx.*sy) + (-uy + y).^2.../sy.^2).../(2.*(1 - r.^2).*s2.^2)).*(2.*pi.*(1 - r.^2).^(3.../2).*s2.^2.*sx.*sy)) + ...
%     (((-ux + x).*(-uy + y)).../((1 - r.^2).*sx.*sy) - (r.*((-ux + x).^2.../sx.^2 - (2.*r.*(-ux + x).*(-uy + y)).../(sx.*sy) + (-uy + y).^2.../sy.^2)).../(1 - r.^2).^2).../...
%     (exp((((-ux + x).^2.../sx.^2 - (2.*r.*(-ux + x).*(-uy + y)).../(sx.*sy) + (-uy + y).^2.../sy.^2).../(2.*(1 - r.^2))).*(2.*pi.*sqrt(1 - r.^2).*sx.*sy)) - ...
%     (b.*(((-ux + x).*(-uy + y)).../((1 - r.^2).*s2.^2.*sx.*sy) - (r.*((-ux + x).^2.../sx.^2 - (2.*r.*(-ux + x).*(-uy + y)).../(sx.*sy) + (-uy + y).^2.../sy.^2)).../((1 - r.^2).^2.*s2.^2))).../...
%     (exp((((-ux + x).^2.../sx.^2 - (2.*r.*(-ux + x).*(-uy + y)).../(sx.*sy) + (-uy + y).^2.../sy.^2).../(2.*(1 - r.^2).*s2.^2)).*(2.*pi.*sqrt(1 - r.^2).*s2.^2.*sx.*sy)));
% 
% 
% part_s2 = -N2.../s2 .*( 2 + exp(on.../(1-r));
% 
% part_io = Ihat.../io;
% 
% part_b = -io.*N2;
% 
% part_ux = -Ihat.../(1-r).*(jointterm-xterm).../(x-ux);
% 
% part_uy = -Ihat.../(1-r).*(jointterm-yterm).../(y-uy);

