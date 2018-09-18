function [b] = vipblkdrawshapes(varargin)
% VIPBLKROIDISPLAY Mask dynamic dialog function for Draw Shapes blocku

% Copyright 2003-2006 The MathWorks, Inc.

if nargin==0
    action = 'dynamic';   % mask callback
else
    action = 'icon';
end

blk = gcbh;

switch action
    case 'icon'
        shapeToDraw = get_param(blk, 'shape');
        inLibrary = strcmp(get_param(bdroot(blk),'BlockDiagramType'),'library');
        if inLibrary
            ports.icon = 'Draw\nShapes'; 
        else
            if (strcmp(shapeToDraw,'Rectangles'))
                ports.icon = 'Draw\nRectangles';
            elseif (strcmp(shapeToDraw,'Lines'))
                ports.icon = 'Draw\nLines';
            elseif (strcmp(shapeToDraw,'Polygons'))
                ports.icon = 'Draw\nPolygons';
            else
                ports.icon = 'Draw\nCircles';
            end
        end    
          oldVerObsolete = strcmp(get_param(blk, 'inType'), 'Obsolete') == 1;
          if (oldVerObsolete)
              isSinglePort = strcmp(get_param(blk, 'imagePorts'), 'One multidimensional signal') == 1;
          else
              isSinglePort = strcmp(get_param(blk, 'inType'), 'Intensity') == 1;
          end
        
        if (isSinglePort)
            nextPort = 1;
            ports.iport1=nextPort;
            ports.itxt1='';
            
            ports.iport2=nextPort;
            ports.itxt2='';
            
            ports.iport3=nextPort;
            ports.itxt3='Image';
            
            nextPort = nextPort + 1;
            ports.iport4=nextPort;
            ports.itxt4='Pts';
            
            if (strcmp(get_param(blk,'viewport'),'Specify region of interest via port'))
                nextPort = nextPort + 1;
                ports.itxt5='ROI';
            else
                ports.itxt5='';
            end
            ports.iport5=nextPort;
            
            if (strcmp(get_param(blk,'fillClrSource'),'Input port'))
                nextPort = nextPort + 1;
                ports.itxt6 = 'Clr';
            else
                ports.itxt6 = '';
            end
            ports.iport6 = nextPort;
            
            ports.oport1=1;
            ports.otxt1='';
            ports.oport2=1;
            ports.otxt2='';
            ports.oport3=1;
            ports.otxt3='';
        else
            ports.iport1=1;
            ports.itxt1='R';
            ports.iport2=2;
            ports.itxt2='G';
            ports.iport3=3;
            ports.itxt3='B';
            
            ports.iport4=4;
            ports.itxt4='Pts';
            nextPort = 4;
            
            if (strcmp(get_param(blk,'viewport'),'Specify region of interest via port'))
                nextPort = nextPort + 1;
                ports.itxt5='ROI';
            else
                ports.itxt5='';
            end
            ports.iport5=nextPort;
            
            if (strcmp(get_param(blk,'fillClrSource'),'Input port'))
                nextPort = nextPort + 1;
                ports.itxt6 = 'Clr';
            else
                ports.itxt6 = '';
            end
            ports.iport6 = nextPort;
            
            ports.oport1=1;
            ports.otxt1='R';
            ports.oport2=2;
            ports.otxt2='G';
            ports.oport3=3;
            ports.otxt3='B';            
        end
        b = ports;
    otherwise
        error(message('vision:internal:unhandledCase'));
end


% ----------------------------------------------------------
function ports = get_labels(blk)
% Change this to be either I or R,G and B. 
% end of vipblkdrawshapes.m
