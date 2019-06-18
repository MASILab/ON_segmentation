function  params = enforce_contraints(params)
% remember, params are: [sx,sy,r,s1,s2,mx,my,io,b,ux,uy]
%                   or: [sx,sy,r,   s2,mx,my,io,b,ux,uy]

%keep all variances positive
if params(1)<=0
    warning('model_stpdesc:sigma_x_range','Parameter sigma_x out of range');
    params(1) = max(params(1),eps);
end
if params(2)<=0
    warning('model_stpdesc:sigma_y_range','Parameter sigma_y out of range');
    params(2) = max(params(2),eps);
end
if params(4)<=0
    warning('model_stpdesc:sigma_2_range','Parameter sigma_2 out of range');
    params(4) = max(params(4),eps);
end

%     % rho -1<rho<1
%     if abs(params(3))>1
%         warning('model_stpdesc:rho_range','Parameter rho out of range');
%         params(3) = min(max(params(3),-1),1);
% end
end