function varargout = vipblkimsrc(fcn, ImageValue, namechange,FileName)
% VIPBLKIMSRC Mask callback function for Image From Workspace block

% Copyright 1995-2012 The MathWorks, Inc.

blk = gcbh;
ImageDataType = get_param(blk, 'ImageDataType');
ImagePorts    = get_param(blk, 'imagePorts');
needOneNDPort   = strcmp(ImagePorts,'One multidimensional signal');
scalemode = get_param(blk, 'FractionLengthMode');
indices = getParameterIndices(blk);
[ImagePorts, Signed, WordLength, sdImageDataType, FractionLengthMode,...
    FractionLength,iOutPortLabels] = indices{:};
if (fcn == -1)   % dynamic
    maskvis = get_param(blk, 'MaskVisibilities');
    maskvisold = maskvis;
    
    switch ImageDataType
      case 'Fixed-point'
        maskvis{Signed} = 'on';
        maskvis{WordLength} = 'on';
        maskvis{sdImageDataType} = 'off';
        maskvis{FractionLengthMode} = 'on';
        if (strcmp(scalemode, 'User-defined'))
            maskvis{FractionLength} = 'on';
        else
            maskvis{FractionLength} = 'off';
        end
      case 'User-defined'
        maskvis{Signed} = 'off';
        maskvis{WordLength} = 'off';
        maskvis{sdImageDataType} = 'on';
        maskvis{FractionLengthMode} = 'on';
        if (strcmp(scalemode, 'User-defined'))
            maskvis{FractionLength} = 'on';
        else
            maskvis{FractionLength} = 'off';
        end
      otherwise
        maskvis{Signed} = 'off';
        maskvis{WordLength} = 'off';
        maskvis{sdImageDataType} = 'off';
        maskvis{FractionLengthMode} = 'off';
        maskvis{FractionLength} = 'off';
    end
    
    if (needOneNDPort)
        maskvis{iOutPortLabels} = 'off';
    else
        maskvis{iOutPortLabels} = 'on';
    end
    if strcmp(ImageDataType, 'User-defined')
        sdImageDT = get_param(blk,'sdImageDataType');
        if (strncmpi(sdImageDT,'sint',4) || ...
                strncmpi(sdImageDT,'uint',4) || ...
                strncmpi(sdImageDT,'float',5) || ...
                strncmpi(sdImageDT,'sfrac',5) || ...
                strncmpi(sdImageDT,'ufrac',5) || ...
                strncmpi(sdImageDT,'fixdt',5) || ...
                strncmpi(sdImageDT,'numerictype',11))
            %% don't need FL in this case.
            maskvis{FractionLengthMode} = 'off';
            maskvis{FractionLength} = 'off';
        end
    end
    if (~isequal(maskvis, maskvisold))
        set_param(blk, 'MaskVisibilities', maskvis);
    end;
    return;
end
% This mask help file handles 2 different blocks :- Image from file and
% Image from workspace. FileName parameter is empty for 'Image from
% workspace' block, but has appropriate File name in 'Image from file'
% block.
if isempty(FileName)
    % Image from workspace block.
    if isempty(ImageValue)
        imageExists = false;
    else
        imageExists = true;
    end
else
    % Image from file block.
    FileName = get_param(blk, 'FileName');
    if ~exist(FileName,'file')
        [resFileName imageExists] = slResolve(FileName,blk,'expression'); %#ok
        if ~isempty(resFileName)
            FileName = resFileName;
        end
    end
    if (exist(FileName,'file'))
        imageExists = true;
        ImageValue=imread(FileName);
    else
        imageExists = false;
    end
end
varnamechange = namechange;
if (fcn == 1) && imageExists
    intmaxs08 = double(intmax('int8')); %#ok
    intmaxs16 = double(intmax('int16')); %#ok
    intmaxs32 = double(intmax('int32')); %#ok
    intmaxu08 = double(intmax('uint8'));
    intmaxu16 = double(intmax('uint16'));
    intmaxu32 = double(intmax('uint32'));

    intmins08 = double(intmin('int8'));
    intmins16 = double(intmin('int16'));
    intmins32 = double(intmin('int32'));

    v = ImageValue;
    if ~isreal(v)
       error(message('vision:vipblkimsrc:invalidComplexity'));
    end
            
    if (strcmp(ImageDataType, 'double'))    %im2double
        varnamechange = 1;
        v = getDblValAfterScaling(ImageValue);
    end

    if (strcmp(ImageDataType, 'single'))    %im2single
        varnamechange = 1;
        if (isa(ImageValue, 'uint8'))
            v = single(ImageValue)/255;
        elseif (isa(ImageValue, 'uint16'))
            v = single(ImageValue)/intmaxu16;
        elseif (isa(ImageValue, 'uint32'))
            v = single(ImageValue)/intmaxu32;
        elseif (isa(ImageValue, 'int8'))
            v = (single(ImageValue)-intmins08)/intmaxu08;
        elseif (isa(ImageValue, 'int16'))
            v = (single(ImageValue)-intmins16)/intmaxu16;
        elseif (isa(ImageValue, 'int32'))
            v = (single(ImageValue)-intmins32)/intmaxu32;
        elseif (isa(ImageValue, 'double') ||  isa(ImageValue, 'logical'))
            v = single(ImageValue);
        elseif isfi(ImageValue)
            v = single(convertFi2DblAndScale(ImageValue));
        end
    end

    if (strcmp(ImageDataType, 'uint8'))    %im2uint8
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            v = uint8(ImageValue*intmaxu08);
        elseif (isa(ImageValue, 'uint16'))
            v = uint8(ImageValue/257);
        elseif (isa(ImageValue, 'uint32'))
            v = uint8(ImageValue/(65537*257));
        elseif (isa(ImageValue, 'int8'))
            v = uint8(double(ImageValue)-intmins08);
        elseif (isa(ImageValue, 'int16'))
            v = uint8((double(ImageValue)-intmins16)/257);
        elseif (isa(ImageValue, 'int32'))
            v = uint8((double(ImageValue)-intmins32)/(65537*257));
        elseif (isa(ImageValue, 'logical'))
            v = uint8(ImageValue);
            v(ImageValue) = 255;
        elseif isfi(ImageValue)
            v = convertFi2DblAndScale(ImageValue);
            v = uint8(v*intmaxu08);
        end
    end

    if (strcmp(ImageDataType, 'uint16'))    %im2uint16
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            v = uint16(ImageValue*intmaxu16);
        elseif (isa(ImageValue, 'uint8'))
            v = uint16(ImageValue)*257;
        elseif (isa(ImageValue, 'uint32'))
            v = uint16(ImageValue/65537);
        elseif (isa(ImageValue, 'int8'))
            v = uint16((int32(ImageValue)-intmins08)*257);
        elseif (isa(ImageValue, 'int16'))
            v = uint16(double(ImageValue)-intmins16);
        elseif (isa(ImageValue, 'int32'))
            v = uint16((double(ImageValue)-intmins32)/65537);
        elseif (isa(ImageValue, 'logical'))
            v = uint16(ImageValue);
            v(ImageValue) = 65535;
        elseif isfi(ImageValue)
            v = convertFi2DblAndScale(ImageValue);
            v = uint16(v*intmaxu16);
        end
    end

    if (strcmp(ImageDataType, 'uint32'))    %im2uint32
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            v = uint32(ImageValue*intmaxu32);
        elseif (isa(ImageValue, 'uint8'))
            v = uint32(ImageValue)*65537*257;
        elseif (isa(ImageValue, 'uint16'))
            v = uint32(double(ImageValue)*65537);
        elseif (isa(ImageValue, 'int8'))
            v = uint32((double(ImageValue)-intmins08)*65537*257);
        elseif (isa(ImageValue, 'int16'))
            v = uint32(double(ImageValue)-intmins16)*65537;
        elseif (isa(ImageValue, 'int32'))
            v = uint32(double(ImageValue)-intmins32);
        elseif (isa(ImageValue, 'logical'))
            v = uint32(ImageValue);
            v(ImageValue) = intmax('uint32');
        elseif isfi(ImageValue)
            v = convertFi2DblAndScale(ImageValue);
            v = uint32(v*intmaxu32);
        end
    end


    if (strcmp(ImageDataType, 'int8'))    %im2int8
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            v = int8(round(ImageValue*255)+intmins08);
        elseif (isa(ImageValue, 'uint8'))
            v = int8(double(ImageValue)+intmins08);
        elseif (isa(ImageValue, 'uint16'))
            v = int8(double(ImageValue)/257+intmins08);
        elseif (isa(ImageValue, 'uint32'))
            v = int8(double(ImageValue)/(65537*257)+intmins08);
        elseif (isa(ImageValue, 'int16'))
            v = int8((double(ImageValue)+32768)/257+intmins08);
        elseif (isa(ImageValue, 'int32'))
            v = int8((double(ImageValue)-intmins32)/(65537*257)+intmins08);
        elseif (isa(ImageValue, 'logical'))
            v = int8(ImageValue);
            v(ImageValue) = intmax('int8');
            v(~ImageValue) = intmin('int8');
        elseif isfi(ImageValue)
            v = convertFi2DblAndScale(ImageValue);
            v = int8(round(v*255)+intmins08);
        end
    end

    if (strcmp(ImageDataType, 'int16'))    %im2int16
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            v = int16(round(ImageValue*65535)+intmins16);
        elseif (isa(ImageValue, 'uint8'))
            v = int16(double(ImageValue)*257+intmins16);
        elseif (isa(ImageValue, 'uint16'))
            v = int16(double(ImageValue)+intmins16);
        elseif (isa(ImageValue, 'uint32'))
            v = int16(double(ImageValue)/65537+intmins16);
        elseif (isa(ImageValue, 'int8'))
            v = int16((double(ImageValue)+128)*257+intmins16);
        elseif (isa(ImageValue, 'int32'))
            v = int16((double(ImageValue)-intmins32)/65537+intmins16);
        elseif (isa(ImageValue, 'logical'))
            v = int16(ImageValue);
            v(ImageValue) = intmax('int16');
            v(~ImageValue) = intmin('int16');
        elseif isfi(ImageValue)
            v = convertFi2DblAndScale(ImageValue);
            v = int16(round(v*65535)+intmins16);
        end
    end

    if (strcmp(ImageDataType, 'int32'))    %im2int32
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            v = int32(round(ImageValue*intmaxu32)+intmins32);
        elseif (isa(ImageValue, 'uint8'))
            v = int32(double(ImageValue)*65537*257+intmins32);
        elseif (isa(ImageValue, 'uint16'))
            v = int32(double(ImageValue)*65537+intmins32);
        elseif (isa(ImageValue, 'uint32'))
            v = int32(double(ImageValue)+intmins32);
        elseif (isa(ImageValue, 'int8'))
            v = int32((double(ImageValue)-intmins08)*65537*257+intmins32);
        elseif (isa(ImageValue, 'int16'))
            v = int32((double(ImageValue)-intmins16)*65537+intmins32);
        elseif (isa(ImageValue, 'logical'))
            v = int32(ImageValue);
            v(ImageValue) = intmax('int32');
            v(~ImageValue) = intmin('int32');
        elseif isfi(ImageValue)
            v = convertFi2DblAndScale(ImageValue);
            v = int32(round(v*intmaxu32)+intmins32);
        end
    end

    if (strcmp(ImageDataType, 'Fixed-point') ||  ...
            strcmp(ImageDataType, 'User-defined'))
        varnamechange = 1;
        [retDtype, fiInfo] = parseOutFixedPtDType(blk,ImageValue,ImageDataType);
        if (isa(ImageValue,'double') || isa(ImageValue,'single'))
            dblval = ImageValue;
        elseif (isa(ImageValue, 'uint8'))
            fiObj = fi(ImageValue,0,8,0);
            dblval = convertFi2DblAndScale(fiObj);
        elseif (isa(ImageValue, 'uint16'))
            fiObj = fi(ImageValue,0,16,0);
            dblval = convertFi2DblAndScale(fiObj);
        elseif (isa(ImageValue, 'uint32'))
            fiObj = fi(ImageValue,0,32,0);
            dblval = convertFi2DblAndScale(fiObj);
        elseif (isa(ImageValue, 'int8'))
            fiObj = fi(ImageValue,1,8,0);
            dblval = convertFi2DblAndScale(fiObj);
        elseif (isa(ImageValue, 'int16'))
            fiObj = fi(ImageValue,1,16,0);
            dblval = convertFi2DblAndScale(fiObj);
        elseif (isa(ImageValue, 'int32'))
            fiObj = fi(ImageValue,1,32,0);
            dblval = convertFi2DblAndScale(fiObj);
        elseif (isa(ImageValue, 'logical'))
            dblval = double(ImageValue);
        elseif isfi(ImageValue)
            dblval = convertFi2DblAndScale(ImageValue);
        end
        if strcmp(retDtype,'double')
            v = dblval;
        elseif strcmp(retDtype,'single')
            v = single(dblval);
        else
            [minVal, maxVal] = getMinMaxValForFi(fiInfo);
            v = (dblval*maxVal)+minVal;
            v = fi(v,fiInfo.Signed,fiInfo.WordLength,fiInfo.FractionLength);
        end
    end

    if (strcmp(ImageDataType, 'boolean'))    %im2logical
        varnamechange = 1;
        if (isa(ImageValue,'double') || isa(ImageValue,'single') || ...
                isa(ImageValue, 'uint8') || isa(ImageValue, 'uint16') || ...
                isa(ImageValue, 'uint32'))
            v = logical(ImageValue);
        elseif (isa(ImageValue, 'int8'))
            v = logical(double(ImageValue)-intmins08);
        elseif (isa(ImageValue, 'int16'))
            v = logical(double(ImageValue)-intmins16);
        elseif (isa(ImageValue, 'int32'))
            v = logical(double(ImageValue)-intmins32);
        elseif isfi(ImageValue)
            v = getDblValAfterScaling(ImageValue);
            v = logical(v);
        end
    end
    varargout(1) = {v};
    varargout(2) = {varnamechange};
    return;
else
    if isempty(ImageValue) %if the parameter is not defined let us keep old numports
        if (needOneNDPort)
            numports = 1;
        else
            numports = 3;
        end
    else
        sz = size(ImageValue);
        dims = length(sz);
        if (dims > 3)
            error(message('vision:vipblkimsrc:invalidDimension'));
        end
        if ((dims == 1) || (dims == 2) || needOneNDPort)
            numports = 1;
        else
            numports = sz(3);
        end
    end
    outports = find_system(gcb,'LookUnderMasks','all', ...
        'FollowLinks', 'on', 'BlockType','Outport');
    numoldports = length(outports);

    outportpos = [140    40   170    54];
    constpos = [25    27    65    63];

    outportpos([2, 4]) = outportpos([2, 4]) + numoldports*75;
    constpos([2, 4]) = constpos([2, 4]) + numoldports*75;
    if (numports > numoldports) %add new blocks
        for i=numoldports+1:numports
            istr = int2str(i);
            add_block('built-in/Constant', [gcb '/Constant' istr], ...
                'SampleTime', 'Ts', ...
                'OutDataTypeStr', 'slDataTypeAndScale(''sdImageDataType'',''ImageScaleValue'')', ...
                'Position', constpos);
            add_block('built-in/Outport', [gcb '/Out' istr], ...
                'Position', outportpos);
            add_line(gcb, ['Constant' istr '/1'], ['Out' istr '/1']);
            outportpos([2, 4]) = outportpos([2, 4]) + 75;
            constpos([2, 4]) = constpos([2, 4]) + 75;
        end
    else
        for i=numports+1:numoldports
            istr = int2str(i);
            delete_line(gcb, ['Constant' istr '/1'], ['Out' istr '/1']);
            delete_block([gcb '/Constant' istr]);
            delete_block([gcb '/Out' istr]);
        end
    end

    % set data type parameters
    % default values
    if (strcmp(ImageDataType, 'Fixed-point'))

        % get sign
        if strcmp(get_param(blk, 'Signed'),'on') 
            sign = '1';
        else
            sign = '0';
        end

        % get word length and validate it
        wordlength = get_param(blk, 'WordLength');
        wordLen_value = slResolve(wordlength, blk, 'expression');

        % We have the throw the error here because the function fixdt 
        % silently modifies invalid word length without issuing error.
        if ~isnumeric(wordLen_value) || ~isscalar(wordLen_value) || wordLen_value <= 0
            throw(MSLException(blk, ...
                               message('Simulink:fixedandfloat:InvWordLength',wordLen)));
        end

        % get scaling
        if (strcmp(scalemode, 'User-defined'))
            fraclength = get_param(blk, 'FractionLength');
            fracLength_value = slResolve(fraclength, blk, 'expression');
            if ~isnumeric(fracLength_value) || ~isscalar(fracLength_value) || ...
                    fracLength_value ~= round(fracLength_value)

                throw(MSLException(blk, ...
                                   message('Simulink:fixedandfloat:InvFractionLength',fraclength)));
            end
            outscaling = [',(' fraclength ')'];
        else
            outscaling = '';
        end

        % assemble the data type string
        outdatatypestr = [ 'fixdt(' sign ',' wordlength outscaling ')'];
    elseif (strcmp(ImageDataType, 'User-defined'))
        outdatatype = get_param(blk, 'sdImageDataType');

        if dspDataTypeDeterminesFracBits(outdatatype)
            outdatatypestr = outdatatype;
        else
            if (strcmp(scalemode, 'User-defined'))
                fraclength = get_param(blk, 'FractionLength');
                fracLength_value = slResolve(fraclength, blk, 'expression');
                if ~isnumeric(fracLength_value) || ~isscalar(fracLength_value) || ...
                        fracLength_value ~= round(fracLength_value)
                    throw(MSLException(blk, ...
                                       message('Simulink:fixedandfloat:InvFractionLength',fraclength)));
                end
                outscaling = ['2^(-(' fraclength '))'];
            else
                outscaling = '';
            end
            if isempty(outscaling)
                outdatatypestr = outdatatype;
            else
                outdatatypestr = ['slDataTypeAndScale(''' outdatatype ''',''' outscaling ''')'];
            end
        end
    elseif strcmp(ImageDataType, 'Inherit from ''Value''') || ...  %from workspace
            strcmp(ImageDataType, 'Inherit from input image') %from file
        %Inherit from value mapped to Inherit from constant value (default)
        outdatatypestr = 'Inherit: Inherit from ''Constant value''';
    else
        % Simulink built-int types
        outdatatypestr = get_param(blk, 'ImageDataType');
        if strcmp(outdatatypestr, 'Inherit via back propagation')
            outdatatypestr = ['Inherit: ' outdatatypestr];
        end        
    end

    if (varnamechange)
        if (needOneNDPort)
            varname = 'v';
        else
            varname = 'v(:,:,';
        end
    else
        if (needOneNDPort)
            varname = 'ImageValue';
        else
            varname = 'ImageValue(:,:,';
        end
    end
    constBlockCommonName = [gcb '/Constant'];% without the block index at the end.    
    for i=1:numports
        if (~needOneNDPort)
            istr = int2str(i);
            name = [varname istr ')'];
        else
            name = varname;
        end
        set_param([constBlockCommonName,num2str(i)], ...
                  'OutDataTypeStr', outdatatypestr, ...
                  'Value', name);
    end

    if (strcmp(get_param(blk, 'MaskType'), 'Image From File'))
        [pathstr, name, ext] = fileparts(FileName); %#ok
        maskdisplay = [name ext];
        maskdisplay = ['disp(''' maskdisplay ''');'];
    else
        maskdisplay = 'disp(ImageVal);';
    end

    if (needOneNDPort)
        maskdisplay = [maskdisplay 'port_label(''output'',1,''Image'');'];
    else
        R = get_param(blk, 'OutPortLabels');
        for i=1:numports
            istr = int2str(i);
            [T, R] = strtok(R,'|'); %#ok
            T = strrep(T, '''', '''''');
            maskdisplay = [maskdisplay 'port_label(''output'',' istr ',''' T ''');']; %#ok<AGROW>
            if (isempty(R)), break; end
        end
    end
    current_maskdisplay = get_param(blk, 'MaskDisplay');
    if ~strcmp(current_maskdisplay, maskdisplay)
      set_param(blk, 'MaskDisplay', maskdisplay);
    end    
end

% parseOutFixedPtDType function will only be called when output
% imagedatatype is either Fixed-pt or User-specified.
% nested function
    function [retDtype, fiInfo] = parseOutFixedPtDType(blk,ImageValue,ImageDataType)
        fiInfo = [];
        outFL = [];
        retDtype = 'fixed';
        if (strcmp(ImageDataType, 'Fixed-point'))
            outSignedness = strcmp(get_param(blk, 'Signed'),'on');
            outWL = slResolve(get_param(blk,'WordLength'),blk,'expression');
        else  % user-defined case.
            sdImageDT = get_param(blk,'sdImageDataType');
            if (strncmpi(sdImageDT,'sfix',4) || ...
                    strncmpi(sdImageDT,'ufix',4))
                dtype = eval(sdImageDT);
                outSignedness = dtype.IsSigned;
                outWL = dtype.WordLength;
            elseif (strncmpi(sdImageDT,'sint',4) || ...
                    strncmpi(sdImageDT,'uint',4))
                dtype = eval(sdImageDT);
                outSignedness = dtype.IsSigned;
                outWL = dtype.WordLength;
                outFL = 0;
            elseif strncmpi(sdImageDT,'float',5)
                dtype = eval(sdImageDT);
                if dtype.isdouble
                    retDtype = 'double';
                elseif dtype.issingle
                    retDtype = 'single';
                else
                    error(message('vision:vipblkimsrc:invalidUserDefFltptDT'));
                end
            elseif (strncmpi(sdImageDT,'sfrac',5) || ...
                    strncmpi(sdImageDT,'ufrac',5))
                dtype = eval(sdImageDT);
                outSignedness = dtype.IsSigned;
                outWL = dtype.WordLength;
                outFL = dtype.FractionLength;
            elseif (strncmpi(sdImageDT,'fixdt',5) || ...
                    strncmpi(sdImageDT,'numerictype',11))
                dtype = eval(sdImageDT);
                dtypeProp = get(dtype);
                if ((dtypeProp.SlopeAdjustmentFactor == 1) && ...
                        (dtypeProp.Bias == 0))
                    if dtype.isdouble
                        retDtype = 'double';
                    elseif dtype.issingle
                        retDtype = 'single';
                    else
                        outSignedness = dtype.Signed;
                        outWL = dtype.WordLength;
                        outFL = dtype.FractionLength;
                    end
                else
                    error(message('vision:vipblkimsrc:invalidFixptDT'));
                end
            else
                error(message('vision:vipblkimsrc:invalidUserDefDT'));
            end
        end
        outIsFloat = strcmp(retDtype,'double') || strcmp(retDtype,'single');
        if ~outIsFloat
            if (outWL > 32)
                error(message('vision:vipblkimsrc:OutWLgt32'));
            end
            if isempty(outFL)
                if (strcmp(get_param(blk,'FractionLengthMode'),'User-defined'))
                    outFL = slResolve(get_param(blk,'FractionLength'),blk,'expression');
                else % Best-precision
                    maxInVal = max(ImageValue(:));
                    if (isa(ImageValue,'double') || isa(ImageValue,'single'))
                        dblval = maxInVal;
                    else
                        dblval = getDblValAfterScaling(maxInVal);
                    end
                    var = fi(dblval,outSignedness,outWL);
                    outFL = var.FractionLength;
                end
            end
            fiInfo = fi(0, outSignedness, outWL, outFL);
        end
    end

% nested function.
    function dblVal = getDblValAfterScaling(ImageValue)
        if (isa(ImageValue, 'uint8'))
            dblVal = double(ImageValue)/intmaxu08;
        elseif (isa(ImageValue, 'uint16'))
            dblVal = double(ImageValue)/intmaxu16;
        elseif (isa(ImageValue, 'uint32'))
            dblVal = double(ImageValue)/intmaxu32;
        elseif (isa(ImageValue, 'int8'))
            dblVal = (double(ImageValue)-intmins08)/intmaxu08;
        elseif (isa(ImageValue, 'int16'))
            dblVal = (double(ImageValue)-intmins16)/intmaxu16;
        elseif (isa(ImageValue, 'int32'))
            dblVal = (double(ImageValue)-intmins32)/intmaxu32;
        elseif (isa(ImageValue, 'single') || isa(ImageValue, 'logical'))
            dblVal = double(ImageValue);
        elseif isfi(ImageValue)
            dblVal = convertFi2DblAndScale(ImageValue);
        elseif isa(ImageValue, 'double') 
			dblVal = ImageValue;
        end
    end

end %end function


function v = convertFi2DblAndScale(ImageValue)
if (ImageValue.WordLength > 32)
    error(message('vision:vipblkimsrc:InWLgt32'));
end
[minForFi, maxForFi] = getMinMaxValForFi(ImageValue);
v = (double(ImageValue) - minForFi)/maxForFi;
end

function [minForFi, maxForFi] = getMinMaxValForFi(fiObj)
precision = (2^fiObj.FractionLength);
if (fiObj.Signed)
    minForFi = -(2^(fiObj.WordLength-1))/precision;
else
    minForFi = 0;
end
maxForFi = ((2^fiObj.WordLength)-1)/precision;
end

function maskIndices = getParameterIndices(blk)
    maskNames = get_param(blk, 'MaskNames');
    maskIndices = cell(1, 7);
    
    for i = 1:numel(maskNames)
        switch(maskNames{i})
            case 'imagePorts'
                maskIndices{1} = i;
            case 'Signed'
                maskIndices{2} = i;
            case 'WordLength'
                maskIndices{3} = i;
            case 'sdImageDataType'
                maskIndices{4} = i;
            case 'FractionLengthMode'
                maskIndices{5} = i;
            case 'FractionLength'
                maskIndices{6} = i;
            case 'OutPortLabels'
                maskIndices{7} = i;
        end
    end
end