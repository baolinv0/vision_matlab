function UpdateApplyGeometricTransformation(block, h)
% method for converting Apply Geometric Transformation to Warp

if askToReplace(h, block)
    
    oldEntries = GetMaskEntries(block);
    TransformMatrixSource = oldEntries{1};
    TransformMatrix = oldEntries{2};
    roiMethod = oldEntries{5};
    ROIInputPort = oldEntries{6};
    ROIValidityOutputPort = oldEntries{9};
    InterpolationMethod = oldEntries{10};
    BackgroundFillValue = oldEntries{11};
    OutputImagePositionSource = oldEntries{12};
    OutputImageHW = oldEntries{13};
    OutputImageXY = oldEntries{14};
    SimulateUsing = 'Interpreted execution'; % default
    
     % replace [] in expression
    OutputImageHWParsed = regexprep(OutputImageHW,'\[|\]','');
    OutputImageXYParsed = regexprep(OutputImageXY,'\[|\]','');
    
    % Output Size and Location in Warp block is 1-based.
    % add 1 to the old [x,y] coordinate    
    OutputXYNew = strsplit(OutputImageXYParsed,{' ',','});
    OutputXYRes = '';
    for idx = 1:numel(OutputXYNew)
        OutputXYNew{idx} = deblank(OutputXYNew{idx});
        OutputXYNew{idx} = regexprep(OutputXYNew{idx},',','');
        OutputXYNew{idx} = [OutputXYNew{idx}, '+1'];
        if isempty(OutputXYRes)
            OutputXYRes = OutputXYNew{idx};
        else            
            OutputXYRes = [OutputXYRes,',',OutputXYNew{idx}]; %#ok<AGROW>
        end
    end
    
    % Flip [height,width] in the old block
    OutputImagePosition = ['[',OutputXYRes,',','fliplr([', OutputImageHWParsed '])',']'];
    
    
    if strcmpi(ROIInputPort,'Input port') && ~strcmpi(roiMethod,'Whole input image')
        ROIInputPort = 'on';
    else
        % The Warp block only accepts ROI via input port
        ROIInputPort = 'off';
    end
    
    if strcmpi(TransformMatrixSource,'Specify via Dialog')
        TransformMatrixSource = 'Custom';
    end
    
    if strcmpi(OutputImagePositionSource,'Specify via Dialog')
        OutputImagePositionSource = 'Custom';
    end
    
    reasonStr = ['''Apply Geometric Transformation'' will ' ...
        'be removed in a future release. Please use ''Warp'' block instead'];
    
    funcSet = uReplaceBlock(h, block, ...
        'visiongeotforms/Warp',...
        'TransformMatrix',TransformMatrix ,...
        'TransformMatrixSource',TransformMatrixSource,...
        'OutputImagePositionSource',OutputImagePositionSource,...
        'OutputImagePosition',OutputImagePosition,...
        'InterpolationMethod',InterpolationMethod,...
        'BackgroundFillValue', BackgroundFillValue,...
        'ROIInputPort',ROIInputPort,...
        'SimulateUsing',SimulateUsing,...
        'ROIValidityOutputPort',ROIValidityOutputPort...
        );
        
    appendTransaction(h, block, reasonStr, {funcSet});
end