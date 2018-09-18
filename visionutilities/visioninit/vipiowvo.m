function [portLabels hwnd] = vipiowvo(action,varargin) %#ok
% VIPIOWVO Mask helper function for To Video Display block

% Copyright 1995-2014 The MathWorks, Inc.

blk = gcbh;
if nargin==0, action='dynamic'; end

switch action
    case 'init'
        portLabels = struct([]);        
        % this is an obsolete option that we inspect for backward compatibility
        inputTypeStr = get_param(blk, 'inputType');
        
        if strcmp(inputTypeStr, 'Obsolete')
            % This option already underwent obsoletion process; we are now
            % processing for the new setting
            isSinglePort = strcmp(get_param(blk, 'imagePorts'),...
                'One multidimensional signal') == 1;
        elseif strcmp(get_param(blk, 'inputType'), 'Intensity') % intensity            
            % This is an obsolete choice.  Reset the mask to map to new
            % settings and mark 'inputType' as 'Obsolete' so that it's not 
            % considered in the future.
            isSinglePort = true;
            set_param(blk, 'imagePorts', 'One multidimensional signal');
            set_param(blk, 'inputType', 'Obsolete');
        else % rgb
            isSinglePort = false;
            set_param(blk, 'imagePorts', 'Separate color signals');
            set_param(blk, 'inputType', 'Obsolete');
        end
        
        inputColorFormat = get_param(blk, 'inputColorFormat');
        if strcmp(inputColorFormat, 'RGB')
            if isSinglePort
                [portLabels(1:3).port] = deal(1,1,1);
                [portLabels(1:3).txt]  = deal('Image','','');
            else
                [portLabels(1:3).port] = deal(1,2,3);
                [portLabels(1:3).txt]  = deal('R','G','B');
            end
        else % YCbCr 4:2:2
            [portLabels(1:3).port] = deal(1,2,3);
            [portLabels(1:3).txt]  = deal('Y','Cb','Cr');            
        end
    case 'dynamic'
        % handle visibility options
        maskVis = get_param(blk,'MaskVisibilities');
        oldMaskVis = maskVis;        
        inputColorFormat = get_param(blk, 'inputColorFormat');
        imgPort_idx = 11;
        if strcmp(inputColorFormat, 'RGB')
            maskVis{imgPort_idx} = 'on';
        else
            maskVis{imgPort_idx} = 'off';
        end
            
        % Change the mask if necessary
        if (~isequal(maskVis, oldMaskVis))
            set_param(blk, 'MaskVisibilities', maskVis);
        end        
end
end
