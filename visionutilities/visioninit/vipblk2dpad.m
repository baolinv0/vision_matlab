function [b] = vipblk2dpad(varargin) %#ok
% VIPBLK2DPAD Mask dynamic dialog function for 2D Pad block

% Copyright 2003-2006 The MathWorks, Inc.

if nargin==0
  action = 'dynamic';   % mask callback
else 
  action = 'icon';
end
blk = gcbh;

switch action
case 'icon'
    b = get_labels(blk);
    
case 'dynamic'
   % Execute dynamic dialogs
   %newVisibles{1} is Method
   %newVisibles{2} is Pad value source
   %newVisibles{3} is Value
   %newVisibles{4} is Specify
   %newVisibles{5} is Pad rows at
   %newVisibles{6} is Output row mode
   %newVisibles{7} is Pad size along rows
   %newVisibles{8} is Number of output columns
   %newVisibles{9} is Pad columns at
   %newVisibles{10} is Output column mode
   %newVisibles{11} is Pad size along columns
   %newVisibles{12} is Number of output rows
   %newVisibles{13} is Action when truncation occurs           
   
   % Cache current block
    this = get_param(gcbh,'Object');
    valueOnDialog = this.MaskValues;
    
   padMethod = valueOnDialog(1);
   padsrc    = valueOnDialog(2);  
   
    mask_visibilities = get_param(blk,'maskvisibilities');
    % Save for comparison
    current_mask_visibilities = mask_visibilities;
    
    % Action when truncation occurs. Enable later under certain conditions.
    mask_visibilities{13} = 'off';
    
    switch padMethod{1}
    case 'Constant'
      mask_visibilities{2} = 'on'; % Pad value source                
      if strcmp(padsrc,'Specify via dialog')
          mask_visibilities{3} = 'on'; % Value          
      else
          mask_visibilities{3} = 'off'; % Value         
      end
    case {'Replicate','Symmetric','Circular'}
      mask_visibilities{2} = 'off'; % Pad value source      
      mask_visibilities{3} = 'off'; % Value               
    otherwise
      error(message('vision:vipblk2dpad:unknownPaddingMethod'));
    end
   mask_visibilities{5} = 'on';  % Pad rows at 
   mask_visibilities{9} = 'on'; % Pad columns at
   
   outMode = valueOnDialog(4);
   rowdir = valueOnDialog(5);
   coldir = valueOnDialog(9);
   rowmode = valueOnDialog(6);
   colmode = valueOnDialog(10);
    
    if strcmp(outMode,'Pad size')                    
       if strcmp(rowdir,'No padding')          
           mask_visibilities{7} = 'off'; % Pad size along rows
       else          
           mask_visibilities{7} = 'on';  % Pad size along rows
       end   

       if strcmp(coldir,'No padding')           
           mask_visibilities{11} = 'off'; % Pad size along columns
       else           
           mask_visibilities{11} = 'on'; % Pad size along columns
       end          
       mask_visibilities{8} = 'off';  % Number of output columns       
       mask_visibilities{12} = 'off'; % Number of output rows             
       mask_visibilities{6} = 'off';  % Output row mode             
       mask_visibilities{10} = 'off'; % Output column mode             
    else % Output size                     
       if strcmp(coldir,'No padding')        
           mask_visibilities{12} = 'off';   % Number of output rows           
           mask_visibilities{10} = 'off'; % Output column mode                 
       else
           if strcmp(colmode, 'Next power of two')
               mask_visibilities{10} = 'on';  % Output column mode                    
               mask_visibilities{12} = 'off';   % Number of output rows                             
           else
               mask_visibilities{10} = 'on';  % Output column mode                     
               mask_visibilities{12} = 'on';  % Number of output rows               
           end
       end
       
       if strcmp(rowdir,'No padding')          
           mask_visibilities{8} = 'off';  % Number of output columns
           mask_visibilities{6} = 'off';   % Output row mode                 
       else
           if strcmp(rowmode, 'Next power of two')
               mask_visibilities{6} = 'on';    % Output row mode                     
               mask_visibilities{8} = 'off';  % Number of output columns                                            
           else               
               mask_visibilities{6} = 'on';    % Output row mode                     
               mask_visibilities{8} = 'on';    % Number of output columns                
           end
       end           
              
       if ((~strcmp(coldir,'No padding') && strcmp(colmode, 'User-specified')) || ...
               (~strcmp(rowdir,'No padding') && strcmp(rowmode, 'User-specified')))
           mask_visibilities{13} = 'on';   % Action when truncation occurs
       end
           
       mask_visibilities{7} = 'off';   % Pad size along rows
       mask_visibilities{11} = 'off';  % Pad size along columns       
    end           
    
    % Only update the block mask enables if they have changed
    if ~(isequal(mask_visibilities, current_mask_visibilities))
      %this.MaskVisibilities = mask_visibilities;
      %this.MaskEnables      = mask_visibilities;
      set_param(blk,'maskvisibilities',mask_visibilities);
      set_param(blk,'maskenables',mask_visibilities);
    end       
      
otherwise
  error(message('vision:internal:unhandledCase'));
end
        

% ----------------------------------------------------------
 function ports = get_labels(blk)   
 padMethod = get_param(blk, 'method');
 if strcmp(padMethod,'Constant')
     padsrc = get_param(blk, 'valSrc');
     if strcmp(padsrc,'Input port')
         ports.type1='input';
         ports.port1=1;
         ports.txt1='Image';

         ports.type2='input';
         ports.port2=2;
         ports.txt2='PVal';

         ports.type3='output';
         ports.port3=1;
         ports.txt3='';
     else
         ports.type1='input';
         ports.port1=1;
         ports.txt1='';

         ports.type2='input';
         ports.port2=1;
         ports.txt2='';

         ports.type3='output';
         ports.port3=1;
         ports.txt3='';
     end
 else
     ports.type1='input';
     ports.port1=1;
     ports.txt1='';

     ports.type2='input';
     ports.port2=1;
     ports.txt2='';

     ports.type3='output';
     ports.port3=1;
     ports.txt3='';
 end

% end of vipblk2dpad.m
