function internalCustomizationVision( obj )
% Copyright 2014-2015 The MathWorks, Inc.
    
    if dig.isProductInstalled( 'Computer Vision System Toolbox', 'Video_and_Image_Blockset' )         
        cm = obj.CustomizationManager; 
        if ~ispc    
            cm.addSigScopeMgrViewerLibrary('vipviewers_all');
        else
            cm.addSigScopeMgrViewerLibrary('vipviewers_win32');
        end
          
        cm.addSigScopeMgrGeneratorLibrary( 'vipgenerators_all' );
    end
end

% EOF

