classdef ImageSideBySideDisplay < handle
    %   Copyright 2014 The MathWorks, Inc.
    
    properties
        % Parent figure handle. Should not be used for anything else.
        hParent               
        lPanel
        rPanel                
    end
    
    methods
        function tool = ImageSideBySideDisplay(hParent_)
            
            assert(isa(hParent_, 'matlab.ui.Figure'),...
                'Expected parent handle to be a MATLAB figure');
            tool.hParent = hParent_;
            
            tool.hParent.Units = 'normalized';
            
            tool.lPanel = uipanel('Parent', tool.hParent,...
                'Tag','leftPanel',...
                'Visible','off',...
                'BackgroundColor','w',...
                'Position',[0 0 .5 1]);
            
            tool.rPanel = uipanel('Parent', tool.hParent,...
                'Tag','rightPanel',...
                'Visible','off',...
                'BackgroundColor','w',...
                'Position',[.5 0 .5 1]);            
        end
        
        function showImages(tool, leftImage, leftTitle, rightImage, rightTitle)
            isTandemPossible = ...
                size(leftImage,1)==size(rightImage,1) ...
                && size(leftImage,2)==size(rightImage,2);
            
            tool.lPanel.Visible = 'on';
            lAxes = vision.internal.ocr.tool.imshowWithCaption(tool.lPanel, ...
                leftImage,...
                leftTitle, ...
                'im');
            
            tool.rPanel.Visible = 'on';
            rAxes = vision.internal.ocr.tool.imshowWithCaption(tool.rPanel, ...
                rightImage,...
                rightTitle, ...
                'imout');

            % Flush before checking for validity
            drawnow;
            if(isTandemPossible && lAxes.isvalid && rAxes.isvalid)
                linkaxes([lAxes, rAxes]);
            end
        end
    end
    
end