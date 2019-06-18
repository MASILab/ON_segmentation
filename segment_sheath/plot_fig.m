function plot_fig(im,im2,sz,e,plotsurface)
% This is a utility function to refresh plots after each iteration

if ~isreal(im2)
    warning('stpdesc:complex_model','model has become complex');
    return;
end

if ~isreal(im) || ~isreal(im2)
    warning('plot_fig:complex','displayed image is only the real part');
    im = real(im);
    im2 = real(im2);
end
if nargin<5
    plotsurface = false;
end

if plotsurface
    subplot(2,2,1);imagesc(reshape(im,sz));title('im');colorbar
    subplot(2,2,2);imagesc(reshape(im2,sz));title('current fit');colorbar
    subplot(2,2,3); surf(reshape(im,sz));title('im');
    subplot(2,2,4); surf(reshape(im2,sz));title('current fit');
else % just 2d
    range = [min(im),max(im)];
    subplot(1,3,1);imagesc(reshape(im,sz),range);title('im');axis image;
    subplot(1,3,2);imagesc(reshape(im2,sz));title('current fit');axis image;
    subplot(1,3,3);imagesc(reshape(abs(im2-im),sz),[0 max(im)]);title(sprintf('error: %.2f',e));axis image;
    
end

drawnow;
end