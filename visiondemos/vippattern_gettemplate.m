function [varargout] = vippattern_gettemplate

if ~strcmp(get_param(gcs, 'SimulationStatus'),'stopped')
    errordlg('Template cannot be changed when simulation is running.',...
        'Cannot change the template');
    return;
end

% Path to Edit Parameters block in the demo
param_path = 'vippattern/Parameters';

% Get the name of AVI file used by the vippattern demo
fmmf_path = 'vippattern/From Multimedia File';
video_filename = get_param(fmmf_path,'inputFilename');

% Read the first frame of the input video and display it on the screen
reader = vision.VideoFileReader(video_filename,...
    'VideoOutputDataType','uint8',...
    'ImageColorSpace','Intensity');
img = step(reader);
release(reader);

figure, imshow(img);

% Place instructions under the image
text(size(img,2)+15,size(img,1)+20, ...
    'Close the figure to accept the region of interest', ...
    'FontSize',15,'Color',[1 0 0], 'HorizontalAlignment','right');

% Pick some initial location for the target rectangle
roi = eval(get_param(param_path,'targetBBox'));
h = imrect(gca, roi);
api = iptgetapi(h);
api.setColor([0 1 0]);
api.addNewPositionCallback(@(p) title(mat2str(p)));

% Don't allow the rectangle to be dragged outside of image boundaries
fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
api.setDragConstraintFcn(fcn);

% Install close figure callback
set(gcf,'CloseRequestFcn',@template_closefcn)

if nargout == 1
    varargout{1} = api;
end

% Custom close figure listener
    function template_closefcn(src, eventdata) %#ok<INUSD>
        % get the roi then destroy the figure
        roi = api.getPosition();
        delete(gcf);
        
        % Extract the template data
        target_img = imcrop(img,roi);
        
        if any(size(target_img) < 20) || any(size(target_img) > 100)
            errordlg('Target height and width must be between 20 and 100 pixels.',...
                'Invalid dimensions');
            return;
        end
        
        % Set the target to be used by the demo
        set_param(param_path,'target',mat2str(target_img));
        set_param(param_path,'targetBBox',mat2str(roi));
        
        % Update the model
        set_param(gcs, 'SimulationCommand', 'update');
    end

end
