function varargout = ocrTrainer(varargin)
%ocrTrainer OCR Training App
%
%  ocrTrainer opens an app for training the ocr function to recognize a
%  custom language or font. The app is used to interactively label
%  character data for OCR training and to generate an OCR language data
%  file that can be used with the ocr function.
%
%  ocrTrainer(sessionFile) opens the app and loads a saved ocr training
%  session. sessionFile is the path to the MAT file containing the saved
%  session.
%
%  See also ocr, ocrText.

%   Copyright 2015 The MathWorks, Inc.

narginchk(0,1);

if nargin == 0
    % Create a new Training Data Labeler
    tool = vision.internal.ocr.tool.OCRTrainer();
    % Render the tool on the screen
    tool.show();
    
elseif nargin == 1

    if strcmpi(varargin{1}, 'close')
        vision.internal.ocr.tool.OCRTrainer.deleteAllTools();
    
    elseif exist(varargin{1}, 'file') || exist([varargin{1}, '.mat'], 'file')
        
        % Load a session
        sessionFileName = varargin{1};
        import vision.internal.calibration.tool.*;
        [sessionPath, sessionFileName] = parseSessionFileName(sessionFileName);
        
        tool = vision.internal.ocr.tool.OCRTrainer();
        tool.show();
        processOpenSession(tool, sessionPath, sessionFileName,false);
      
    else
        error(message('vision:trainingtool:InvalidInput',varargin{1}));
    end
end

if nargout == 1
    varargout{1} = tool;
end