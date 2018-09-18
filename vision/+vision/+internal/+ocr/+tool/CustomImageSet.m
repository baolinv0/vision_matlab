% Custom image set class to provide image pre-processing.
classdef CustomImageSet < imageSet
   properties
       % Pre-processing 
       CustomFcn             
       
       % Text detection params per image
       TextDetectionParams
   end
   
   methods
       function this = CustomImageSet(varargin)
           this = this@imageSet(varargin{:});
       end
       
       function I = read(this, idx)
           I = read@imageSet(this,idx);
           params = this.TextDetectionParams(idx);           
           I = this.CustomFcn(I, params);
       end
   end
end
