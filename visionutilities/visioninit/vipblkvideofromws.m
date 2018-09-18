function vipblkvideofromws(varargin)
% VIPBLKVIDEOFROMWS Mask callback function for Video From Workspace block

% Copyright 1995-2006 The MathWorks, Inc.
%  $Revision $

if (nargin == 0)
    action = 'dynamic';
else 
    action = 'init';
end
blk = gcbh;

ImagePorts    = get_param(blk, 'imagePorts');
needOneNDPort   = strcmp(ImagePorts,'One multidimensional signal');
if (strcmp(action,'dynamic'))   % dynamic
    maskvis = get_param(blk, 'MaskVisibilities');
    maskvisold = maskvis;
    if (needOneNDPort)
        maskvis{6} = 'off';
    else
        maskvis{6} = 'on';
    end
    if (~isequal(maskvis, maskvisold))
        set_param(blk, 'MaskVisibilities', maskvis);
    end;
    return;    
end

if (strcmp(action,'init'))   % dynamic
    R = get_param(blk, 'OutPortLabels');
    if ~strcmp(get_param(blk,'tag'),'vipblks_tmp_nd_forward_compat')
        if ~strcmp(get_param(blk,'finalout'),'Obsolete')
            % this block lives in older version of VIP
            set_param(blk, 'imagePorts','Separate color signals');
            set_param(blk, 'finaloutActive',get_param(blk,'finalout'));
            set_param(blk, 'finalout', 'Obsolete');
        end
    end
    signal = varargin{1};
    maskdisplay = sprintf('%s\n','disp(get_param(gcbh, ''signal''));');
    if (~isempty(signal) && ndims(signal)>=3)    
        try
            if (isstruct(signal))
                p = size(signal(1).cdata,3);
            else
                if (ndims(signal) == 3)
                    p = 1;
                else
                    p = size(signal, 3);
                end
            end
            if (needOneNDPort)
                p = 1;
            end                
        catch
            p = 1;
        end
    else
        if (needOneNDPort)
            p = 1;
        else
            numPorts = get_param(gcb,'ports');
            p = numPorts(2);
        end
    end
    if (needOneNDPort)
        maskdisplay = [maskdisplay 'port_label(''output'',1,''Image'');'];
    else
        for i=1:p
            istr = int2str(i);
            [T, R] = strtok(R,'|');
            T = strrep(T, '''', '''''');
            maskdisplay = [maskdisplay 'port_label(''output'',' istr ',''' T ''');'];
            if (isempty(R)) 
                break;
            end
        end
    end
    set_param(blk, 'MaskDisplay', maskdisplay);
end
