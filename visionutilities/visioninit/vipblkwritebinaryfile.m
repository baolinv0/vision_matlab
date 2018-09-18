function [FrameRatios, PackSizeLoc, FOURCC, numinputs, maskdisplay, Bits]...
    = vipblkwritebinaryfile(NumInputs, Components, comporder, ...
    Bits, VideoFormatStr, BitStreamFormatStr, fourccstr, FileName);
% VIPBLKWRITEBINARYFILE Mask callback function for Write Binary File Block

% Copyright 1995-2006 The MathWorks, Inc.

custom = strcmp(VideoFormatStr, 'Custom');

PackSizeLoc = 0;
FOURCC = 1;
if (custom)
    numinputs = NumInputs;
    FrameRatios = ones(1, 2*numinputs);
    packed = strcmp(BitStreamFormatStr, 'Packed');
    if packed        
        portcount = zeros(1, numinputs);
        try
            for i=1:length(comporder)
                portcount(comporder(i)) = portcount(comporder(i)) + 1;
            end
        catch
            %% S-function will throw error 
            %% set the port count to dummy values
            portcount = 1:numinputs;
        end
        [M, I] = max(portcount);
        for i=1:numinputs
            FrameRatios(2*i) = portcount(I) / portcount(i);
        end
        [M, PackSizeLoc] = min(portcount);
        PackSizeLoc = PackSizeLoc - 1; % Make zero-based
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
    Bits = [FOURCCLIST{i, 5:8}];
    rowratio = FOURCCLIST{FOURCC, 2};
    colratio = FOURCCLIST{FOURCC, 3};
    
    numinputs = FOURCCLIST{FOURCC, 4};
    FrameRatios = ones(1, 2*numinputs);
    for i=2:numinputs
        FrameRatios(i*2-1) = rowratio;
        FrameRatios(i*2)   = colratio;
    end
    if (strcmp(fourccstr, 'Y41T') || strcmp(fourccstr, 'Y42T'))
        FrameRatios(end-1) = 1;
        FrameRatios(end)   = 1;
    end
end

% port labels and icon stuff
[path, name, ext] = fileparts(FileName);
maskdisplay = ['disp(''' name ext ''');'];
if custom
    for i=1:numinputs
        istr = int2str(i);
        ci = Components{i};
		ci = strrep(ci,'''','''''');
        maskdisplay = [maskdisplay 'port_label(''input'',' istr, ',''' ci ''');']; %#ok<AGROW>
    end
else
    maskdisplay = [maskdisplay 'port_label(''input'', 1,''Y'''''');'];
    if (numinputs >= 3)
        maskdisplay = [maskdisplay 'port_label(''input'', 2,''Cb'');'];
        maskdisplay = [maskdisplay 'port_label(''input'', 3,''Cr'');'];
    end
    if (numinputs > 3)
        if strcmp(fourccstr, 'Y41T') || strcmp(fourccstr, 'Y42T')
            maskdisplay = [maskdisplay 'port_label(''input'', 4,''T'');'];
        else
            maskdisplay = [maskdisplay 'port_label(''input'', 4,''A'');'];
        end
    end
end

% [EOF]