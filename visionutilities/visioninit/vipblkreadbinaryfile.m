function [FrameSizes, PackFrameSize, FOURCC, numouts, maskdisplay, Bits,...
    FileName] = ...
    vipblkreadbinaryfile(NumOutputs, Components, comporder, Rows, Cols, ...
                         YRows, YCols, Bits, FileName, VideoFormatStr, ...
                         BitStreamFormatStr, fourccstr, OutputEOF)
% VIPBLKREADBINARYFILE Mask callback function for Read Binary File Block

% Copyright 1995-2006 The MathWorks, Inc.

custom = strcmp(VideoFormatStr,'Custom');

PackFrameSize = [1 1];
FOURCC = 1;

if (custom)
    numouts = NumOutputs;
    
    % pre-process the bits, rows and cols; substitute zeros for empty 
    % fields so that the s-function can do proper error checking,
    % otherwise empty fields collapse in a matrix and the structure
    % (order of fields) is lost
    Bits = parseScalarInputs(Bits(1:numouts), 'Bits');
    Rows = parseScalarInputs(Rows(1:numouts), 'Rows');
    Cols = parseScalarInputs(Cols(1:numouts), 'Cols');

    packed = strcmp(BitStreamFormatStr, 'Packed');
    if ~packed
        FrameSizes = zeros(1, 2*numouts);
        if (isa(Rows,'double') && isa(Cols,'double'))
            if isempty(Rows) || isempty(Cols)
                FrameSizes = [];
            else
                for i=1:numouts
                    FrameSizes(2*i-1) = Rows(i);
                    FrameSizes(2*i)   = Cols(i);
                end
            end
        else
            % cause the s-function to issue an error on non-double input
            if ~isa(Rows,'double')
                FrameSizes = Rows;
            else
                FrameSizes = Cols;
            end
        end
    else
        portcount = zeros(1, numouts);
        for i=1:length(comporder)
            portcount(comporder(i)) = portcount(comporder(i)) + 1;
        end
        [M, I] = max(portcount);

        FrameSizes = parseScalarInputs({YRows, YCols},'Rows and Cols');
        if isa(FrameSizes,'double') && ~isempty(FrameSizes)
            FrameSizes(2*I-1) = YRows;
            FrameSizes(2*I)   = YCols;
            for i=1:numouts
                if i ~= I
                    ratio = portcount(I) / portcount(i);
                    FrameSizes(2*i-1) = FrameSizes(2*I-1);
                    FrameSizes(2*i)   = FrameSizes(2*I)   / ratio;
                end
            end
            [M, I] = min(portcount);
            PackFrameSize(1) = FrameSizes(2*I-1);
            PackFrameSize(2) = FrameSizes(2*I);
        end
    end
else
    % translate fourcc from characters directly to numbers
    FOURCCLIST = vipblkgetFOURCCLIST;
    
    for i=1:size(FOURCCLIST, 1)
        if strcmp(fourccstr, FOURCCLIST{i, 1})
            FOURCC = i;
            break;
        end
    end
    numouts  = FOURCCLIST{FOURCC, 4};
    Bits     = [FOURCCLIST{i, 5:4+numouts}];
    rowratio = FOURCCLIST{FOURCC, 2};
    colratio = FOURCCLIST{FOURCC, 3};

    FrameSizes = parseScalarInputs({YRows, YCols},'Rows and Cols');
    if isa(FrameSizes,'double') && ~isempty(FrameSizes)
        FrameSizes(1) = YRows;
        FrameSizes(2) = YCols;
        for i=2:numouts
            FrameSizes(i*2-1) = FrameSizes(1) / rowratio;
            FrameSizes(i*2)   = FrameSizes(2) / colratio;
        end
        if (strcmp(fourccstr, 'Y41T') || strcmp(fourccstr, 'Y42T'))
            FrameSizes(end-1) = FrameSizes(1);
            FrameSizes(end)   = FrameSizes(2);
        end
    end
end

% check file exists or not
if ~exist(FileName,'file') 
        try
            FileName = slResolve(FileName,gcbh,'expression');
        catch
            % FileName can not be resolved - should fail the isempty check
            % below
        end
end
if isempty(dir(FileName))
    FileName = which(FileName);
    if isempty(FileName)
      error(message('vision:vipblkreadbinaryfile:fileNotFound'));
    end
end

% port labels and icon stuff
[path, name, ext] = fileparts(FileName);
maskdisplay = ['disp(''' name ext ''');'];
if custom
    for i=1:numouts
        istr = int2str(i);
        ci = Components{i};
        ci = strrep(ci,'''','''''');
        maskdisplay = [maskdisplay 'port_label(''output'',' istr, ',''' ci ''');']; %#ok<AGROW>
    end
else
    maskdisplay = [maskdisplay 'port_label(''output'', 1,''Y'''''');'];
    if (numouts >= 3)
        maskdisplay = [maskdisplay 'port_label(''output'', 2,''Cb'');'];
        maskdisplay = [maskdisplay 'port_label(''output'', 3,''Cr'');'];
    end
    if (numouts > 3)
        if strcmp(fourccstr, 'Y41T') || strcmp(fourccstr, 'Y42T')
            maskdisplay = [maskdisplay 'port_label(''output'', 4,''T'');'];
        else
            maskdisplay = [maskdisplay 'port_label(''output'', 4,''A'');'];
        end
    end
end
if strcmp(OutputEOF, 'on')
    maskdisplay = [maskdisplay 'port_label(''output'', '...
        int2str(numouts+1) ',''EOF'');'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This method parses a cell array of inputs to produce a single double
% array that can be handled by the s-function.  This method manipulates 
% the cell array to evoke appropriate error messages in case of failures 
% such as: one of the inputs is empty or it's not a double.  It adjusts the
% data strictly for s-function consumption.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=parseScalarInputs(in, name)

    % if one of the cell array entries is non-double (required by the
    % s-function) expose it by passing only that part of the cell array
    % to the s-function so that a proper error message can be issued
    idx = cellfun(@(x) isa(x,'double'),in);
    if ~all(idx)
        out = in{find(~idx,1)};
    else
        % if one of the inputs is empty, make the entire output empty
        if any(cellfun(@isempty,in))
            out = [];
        else
            if any(cellfun(@issparse,in)) || ~all(cellfun(@isscalar,in))
                error(message('vision:vipblkreadbinaryfile:sparseInput', name));
            end
            out = cell2mat(in);
        end
    end
    
