function save_gif_image(im,model,gif_filename,k,e,done)
[path,name,ext] = fileparts(gif_filename);
if ~strcmp(ext,'gif')
    ext='gif';
end
if strcmp(path,'')
    path=pwd;
end
if ~exist([path,filesep,'tmp'],'dir')
    mkdir([path,filesep,'tmp']);
end
if ~done
    %Just save the intermediate images
    filename=sprintf('%s/%03d.png',fullfile(path,'tmp'),k);
    h=figure('Visible','off');
    subplot(1,2,1);imagesc(im);axis image;title('Target Image');
    subplot(1,2,2);imagesc(model);axis image;title(sprintf('Current Model, Error: %0.2f',e));
    print(h,filename,'-dpng');
    close(h);
else
    %make the gif, write the last image
    filename=sprintf('%s/%03d.png',fullfile(path,'tmp'),k);
    h=figure('Visible','off');
    subplot(1,2,1);imagesc(im);axis image;title('Target Image');
    subplot(1,2,2);imagesc(model);axis image;title(sprintf('Current Model, Error: %0.2f',e));
    print(h,filename,'-dpng'); %#ok<*MCPRT>
    close(h);
    %read them all in:
    fnames = get_fnames_dir([path,filesep,'tmp'],'*.png');
    for i=1:length(fnames)
        im=imread(fnames{i});
        [imind,cm]=rgb2ind(im,256);
        if i==1
            imwrite(imind,cm,[path,filesep,name,'.',ext],'gif','Loopcount',Inf,'DelayTime',0.1);
        else
            imwrite(imind,cm,[path,filesep,name,'.',ext],'gif','WriteMode','append','DelayTime',0.1);
        end
    end
    delete([path,filesep,'tmp/*.png']);
    rmdir([path,filesep,'tmp']);
end

end