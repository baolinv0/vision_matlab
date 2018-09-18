function Igray = convertRGBToGray(I)
% Convert RGB to gray if codegen

%#codegen

if ~ismatrix(I)    
    Igray = rgb2gray(I);    
else
    Igray = I;
end
