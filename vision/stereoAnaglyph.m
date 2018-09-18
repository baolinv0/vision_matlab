function J = stereoAnaglyph(I1, I2)
% stereoAnaglyph Create a red-cyan anaglyph from a stereo pair of images
% 
%   J = stereoAnaglyph(I1, I2) combines images I1 and I2 into
%   a red-cyan anaglyph, which can be viewed with red-blue stereo glasses. 
%   I1 and I2 can be grayscale or truecolor images, and they must have the 
%   same size. J is a truecolor image of the same size as I1 and I2.
% 
%   Class Support
%   -------------
%   I1 and I2 must be logical, uint8, int16, uint16, single, or
%   double, and they must be real and nonsparse. I1 and I2 must be of the 
%   same class. J is of the same class as I1 and I2.  
% 
%   Example 1 - Create a 3-D Stereo Image
%   ------------------------------------
%   % Load parameters of a calibrated stereo camera.
%   load('webcamsSceneReconstruction.mat');
% 
%   % Load a stereo pair of images.
%   I1 = imread('sceneReconstructionLeft.jpg');
%   I2 = imread('sceneReconstructionRight.jpg');
% 
%   % Rectify the stereo images.
%   [J1, J2] = rectifyStereoImages(I1, I2, stereoParams);
% 
%   % Create the anaglyph.
%   A = stereoAnaglyph(J1, J2);
% 
%   % Display the anaglyph.
%   figure; 
%   imshow(A);
%
%   Example 2 - Create a 3-D Stereo Video
%   -------------------------------------
%   % Load parameters of a calibrated stereo camera.
%   load('handshakeStereoParams.mat');
%
%   % Create System Objects for reading the video.
%   readerLeft = vision.VideoFileReader('handshake_left.avi');
%   readerRight = vision.VideoFileReader('handshake_right.avi');
%
%   % Create a System Object for playing the video.
%   player = vision.VideoPlayer('Position', [20, 400, 850, 650]);
%
%   % Create and play the 3-D video, which can be viewed with red-cyan 
%   % stereo glasses.
%
%   while ~isDone(readerLeft) && ~isDone(readerRight)
%       % Read the video frames.
%       frameLeft  = step(readerLeft);
%       frameRight = step(readerRight);
%     
%       % Rectify the frames.
%       [frameLeftRect, frameRightRect] = rectifyStereoImages(frameLeft,...
%           frameRight, stereoParams);
%     
%       % Create the anaglyph.
%       composite = stereoAnaglyph(frameLeftRect, frameRightRect);
%     
%       % Display the anaglyph.
%       step(player, composite);
%   end
%
%   % Clean up.
%   release(readerLeft);
%   release(readerRight);
%   release(player);
% 
%   See also rectifyStereoImages, estimateUncalibratedRectification,
%            imfuse, imshowpair

%  Copyright 2014 The MathWorks, Inc.

%#codegen

vision.internal.inputValidation.validateImagePair(I1, I2, 'I1', 'I2');

isRGB = (ndims(I1) == 3);
if isRGB
    J = cat(3, I1(:,:,1), I2(:,:,2:3));
else
    J = cat(3, I1, I2, I2);
end