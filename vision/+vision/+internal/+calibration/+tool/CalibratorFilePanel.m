classdef CalibratorFilePanel < vision.internal.uitools.FilePanel
    properties(Access=protected)
        NewSessionToolTip  = 'vision:caltool:NewSessionToolTip';
        OpenSessionToolTip = 'vision:caltool:OpenSessionToolTip';
        SaveSessionToolTip = 'vision:caltool:SaveSessionToolTip';
        AddImagesToolTip   = 'vision:caltool:AddImagesToolTip';
        
        AddImagesIconFile = fullfile(toolboxdir('vision'),'vision',...
            '+vision','+internal','+calibration','+tool','AddImage_24.png');
    end
end