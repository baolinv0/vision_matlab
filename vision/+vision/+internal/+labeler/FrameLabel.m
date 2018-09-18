% This class encapsulates an Frame Label. Create instances of this class when
% you want to pass around Frame Label data.
classdef FrameLabel
   properties      
       % Label The text attached to the frame (e.g. rainy, highway, etc.)
       Label
       
       % Description The user provided description of this frame label.
       Description
       
       % Color
       Color
   end
    
   methods
       %-------------------------------------------------------------------       
       function this = FrameLabel(label, description)           
           this.Label = label;
           this.Description = description;
       end
   end
end