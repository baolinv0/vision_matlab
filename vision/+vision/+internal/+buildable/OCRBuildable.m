%#codegen
%#ok<*EMCA>
classdef OCRBuildable < coder.ExternalDependency
         
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'ocr';
        end
        
        function b = isSupportedContext(context)
            b = context.isMatlabHostTarget();
        end
        
        function updateBuildInfo(buildInfo, context)
            usesDefaultModname = true;
            vision.internal.buildable.cvstBuildInfo(buildInfo, context, ...
                'ocrutils', ...
                {'use_tesseract','use_leptonica','use_cpp11compat'},...
                usesDefaultModname);
            
            % PackNGo Note: The language data file used by tesseract is not
            % added to the buildInfo object because
            %   1) tesseract requires the language data file to be saved in
            %      a folder named 'tessdata'
            %   2) folders cannot be added to the buildInfo.
            % 
            % Therefore, the packNGo zip file will not have the language
            % data file included in it. 
        end
        
      
        function [asciiText, ocrMetadata] = tesseract(tessOpts, I, hasROI, resetParameters)                
            
            coder.internal.errorIf(hasROI,'vision:ocr:codegenROIUnsupported');
            
            coder.cinclude('cvstCG_ocrutils.h');
                        
            sizeI  = size(I); 
            height = int32(sizeI(1));
            width  = int32(sizeI(2));
            assert(height > 0);
            assert(width  > 0);
           
            utf8Text  = coder.opaque('char *','NULL');
            txtLength = int32(0);
                        
            textLayout   = nullTerminateString(tessOpts.textLayout);
            characterSet = nullTerminateString(tessOpts.characterSet);                                               
            tessdata     = nullTerminateString(tessOpts.tessdata);                        
            lang         = nullTerminateString(tessOpts.lang);                                  
           
            tessAPIHandle = coder.opaque('void *','NULL');         
            
            if islogical(I)
                
                %> Invoke tesseract and return UTF-8 formatted text.
                txtLength = coder.ceval('tesseractRecognizeTextLogical', ...
                    coder.ref(tessAPIHandle),...
                    coder.ref(I),...
                    coder.ref(utf8Text),...
                    width,...
                    height,...
                    textLayout,...
                    coder.rref(characterSet),... % coder.rref usage forces characterSet var to be generated in code
                    tessdata,...
                    lang, ...
                    resetParameters);
                
            elseif strcmpi(class(I),'uint8')
                
                %> Invoke tesseract and return UTF-8 formatted text.
                txtLength = coder.ceval('tesseractRecognizeTextUint8', ...
                    coder.ref(tessAPIHandle),...
                    coder.ref(I),...
                    coder.ref(utf8Text),...
                    width,...
                    height,...
                    textLayout,...
                    coder.rref(characterSet),... % coder.rref usage forces characterSet var to be generated in code
                    tessdata,... 
                    lang, ...
                    resetParameters);                                                
            end
                              
            if txtLength >= 0
              
                metadata = coder.opaque('void *','NULL');
                
                numChars      = coder.nullcopy(int32(0));
                numWords      = coder.nullcopy(int32(0));
                numTextlines  = coder.nullcopy(int32(0));
                numParagraphs = coder.nullcopy(int32(0));
                numBlocks     = coder.nullcopy(int32(0));
                
                coder.ceval('collectMetadata',...,
                    tessAPIHandle, ...,
                    coder.ref(metadata),...
                    coder.ref(numChars),...
                    coder.ref(numWords),...
                    coder.ref(numTextlines),...
                    coder.ref(numParagraphs),...
                    coder.ref(numBlocks));
                                
                charBBox       = coder.nullcopy(zeros(numChars, 4));
                charWordIndex  = coder.nullcopy(zeros(numChars, 1,'int32'));
                charConfidence = coder.nullcopy(zeros(numChars, 1,'single'));                
                
                wordBBox           = coder.nullcopy(zeros(numWords, 4));
                wordTextLineIndex  = coder.nullcopy(zeros(numWords, 1,'int32'));
                wordConfidence     = coder.nullcopy(zeros(numWords, 1,'single'));
                wordCharacterIndex = coder.nullcopy(zeros(numWords, 2,'int32'));
                
                textlineBBox           = coder.nullcopy(zeros(numTextlines, 4));
                textlineParagraphIndex = coder.nullcopy(zeros(numTextlines, 1,'int32'));
                textlineConfidence     = coder.nullcopy(zeros(numTextlines, 1,'single'));
                textlineCharacterIndex = coder.nullcopy(zeros(numTextlines, 2,'int32'));
                
                paragraphBBox           = coder.nullcopy(zeros(numParagraphs, 4));
                paragraphBlockIndex     = coder.nullcopy(zeros(numParagraphs, 1,'int32'));
                paragraphConfidence     = coder.nullcopy(zeros(numParagraphs, 1,'single'));
                paragraphCharacterIndex = coder.nullcopy(zeros(numParagraphs, 2,'int32'));
                
                blockBBox           = coder.nullcopy(zeros(numBlocks, 4));
                blockPageIndex      = coder.nullcopy(zeros(numBlocks, 1,'int32'));
                blockConfidence     = coder.nullcopy(zeros(numBlocks, 1,'single'));
                blockCharacterIndex = coder.nullcopy(zeros(numBlocks, 2,'int32'));
                
                coder.ceval('copyMetadata',...
                    metadata, ...
                    coder.ref(charBBox), coder.ref(charWordIndex),  coder.ref(charConfidence),...
                    coder.ref(wordBBox), coder.ref(wordTextLineIndex), coder.ref(wordConfidence), coder.ref(wordCharacterIndex),...
                    coder.ref(textlineBBox), coder.ref(textlineParagraphIndex), coder.ref(textlineConfidence), coder.ref(textlineCharacterIndex),...
                    coder.ref(paragraphBBox), coder.ref(paragraphBlockIndex), coder.ref(paragraphConfidence), coder.ref(paragraphCharacterIndex),...
                    coder.ref(blockBBox), coder.ref(blockPageIndex), coder.ref(blockConfidence), coder.ref(blockCharacterIndex));                                     
                
                ocrMetadata.CharacterBBox = charBBox;
                ocrMetadata.CharacterWordIndex = charWordIndex;
                ocrMetadata.CharacterConfidence = charConfidence;      
                
                ocrMetadata.WordBBox = wordBBox;
                ocrMetadata.WordTextLineIndex = wordTextLineIndex;
                ocrMetadata.WordConfidence = wordConfidence;
                ocrMetadata.WordCharacterIndex = wordCharacterIndex;
                
                ocrMetadata.TextLineBBox = textlineBBox;
                ocrMetadata.TextLineParagraphIndex = textlineParagraphIndex;
                ocrMetadata.TextLineConfidence = textlineConfidence;
                ocrMetadata.TextLineCharacterIndex = textlineCharacterIndex;
                
                ocrMetadata.ParagraphBBox = paragraphBBox;
                ocrMetadata.ParagraphBlockIndex = paragraphBlockIndex;
                ocrMetadata.ParagraphConfidence = paragraphConfidence;
                ocrMetadata.ParagraphCharacterIndex = paragraphCharacterIndex;
                
                ocrMetadata.BlockBBox = blockBBox;
                ocrMetadata.BlockPageIndex = blockPageIndex;
                ocrMetadata.BlockConfidence = blockConfidence;
                ocrMetadata.BlockCharacterIndex = blockCharacterIndex;                                                                                                  
                
                tmp = coder.nullcopy(zeros(1,txtLength, 'uint8'));
                
                %> Copy UTF-8 encoded text into temporary buffer and cleanup.
                coder.ceval('copyTextAndCleanup', utf8Text,...
                    coder.ref(tmp),txtLength);
                
                %> Convert UTF-8 text to ASCII text.
                asciiText = char(utf8ToAscii(tmp));      
                
                if numel(asciiText) ~= numChars
                    % Text does not match what is in metadata. Get text
                    % from metadata instead to maintain consistency.
                    
                    metadataText = coder.opaque('char *','NULL');

                    % get text from metadata
                    len = coder.nullcopy(zeros(1,'int32'));                                        
                    len = coder.ceval('getTextFromMetadata', metadata, coder.ref(metadataText));

                    % copy text into output buffer
                    tmpText = coder.nullcopy(zeros(1,len, 'uint8'));                   
                    coder.ceval('copyTextAndCleanup', metadataText,...
                        coder.ref(tmpText),len);
                    
                    %> Convert UTF-8 text to ASCII text.
                    ocrMetadata.Characters = char(utf8ToAscii(tmpText)); 
                    
                else
                    ocrMetadata.Characters = '';
                end                                    
                 
                coder.ceval('cleanupMetadata', metadata);                    
                coder.ceval('cleanupTesseract', tessAPIHandle);      
                
            else
                % An error occurred while running tesseract.               
                
                coder.internal.errorIf(txtLength == int32(-1),...
                    'vision:ocr:codegenInitFailure');
                
                coder.internal.errorIf(txtLength == int32(-2), ...
                    'vision:ocr:codegenMemAllocFailure');
                
                coder.internal.errorIf(txtLength == int32(-3), ...
                    'vision:ocr:codegenInternalError');               
                                
                % codegen requires all execution paths to assign outputs                
                asciiText   = char(zeros(1,0,'uint8'));
                ocrMetadata.CharacterBBox       = zeros(0, 4);
                ocrMetadata.CharacterWordIndex  = zeros(0, 1,'int32');
                ocrMetadata.CharacterConfidence = zeros(0, 1,'single');
                
                ocrMetadata.WordBBox = zeros(0, 4);
                ocrMetadata.WordTextLineIndex = zeros(0, 1,'int32');
                ocrMetadata.WordConfidence = zeros(0, 1,'single');
                ocrMetadata.WordCharacterIndex = zeros(0, 2,'int32');
                
                ocrMetadata.TextLineBBox = zeros(0, 4);
                ocrMetadata.TextLineParagraphIndex = zeros(0, 1,'int32');
                ocrMetadata.TextLineConfidence = zeros(0, 1,'single');
                ocrMetadata.TextLineCharacterIndex = zeros(0, 2,'int32');
                
                ocrMetadata.ParagraphBBox = zeros(0, 4);
                ocrMetadata.ParagraphBlockIndex = zeros(0, 1,'int32');
                ocrMetadata.ParagraphConfidence = zeros(0, 1,'single');
                ocrMetadata.ParagraphCharacterIndex = zeros(0, 2,'int32');
                
                ocrMetadata.BlockBBox = zeros(0, 4);
                ocrMetadata.BlockPageIndex = zeros(0, 1,'int32');
                ocrMetadata.BlockConfidence = zeros(0, 1,'single');
                ocrMetadata.BlockCharacterIndex = zeros(0, 2,'int32'); 
                
                ocrMetadata.Characters = '';             
            end
            
        end
    end   
end

% -------------------------------------------------------------------------
% Convert UTF-8 encoded text into ASCII. Multibyte characters are truncated
% to char(127). 
% -------------------------------------------------------------------------
function asciiText = utf8ToAscii(utf8Text)
coder.inline('never');
idx = findCharacters(utf8Text);
    
asciiText = utf8Text(idx);
asciiText(asciiText>uint8(127)) = uint8(127);
end

% -------------------------------------------------------------------------
% Returns indices to the start of characters in a UTF-8 encoded string,
% skipping over UTF-8 continuation bytes. The number of characters is also
% returned.
% -------------------------------------------------------------------------
function [idx, count, invalidIndex] = findCharacters(utf8String)
coder.inline('never');
bytesToProcess = length(utf8String);

idx = false(1,bytesToProcess);

invalidIndex = false(1,bytesToProcess);

i = 1; count = 0;

while bytesToProcess
    
    count  = count + 1;
    idx(i) = true;
         
    if isASCIICompatiable(utf8String(i))
        
        i = i + 1;
        bytesToProcess = bytesToProcess - 1;        
        
    elseif isUTF8ContinuationByte(utf8String(i))
        
         invalidIndex(i) = true;
         i = i + 1;
         bytesToProcess = bytesToProcess - 1; 
         
    elseif isStartOfUTF8MultiByteCharacter(utf8String(i))
        
        numBytes = numBytesInSequence(utf8String(i));
               
        % skip over the multi-byte sequence
        i = i + numBytes;    
        bytesToProcess = bytesToProcess - numBytes;        
        
    else    
        invalidIndex(i) = true;
        i = i + 1;
        bytesToProcess = bytesToProcess - 1;        
    end
end

end

% -------------------------------------------------------------------------
% Return true if the UTF-8 byte holds an ASCII compatible value.
% -------------------------------------------------------------------------
function tf = isASCIICompatiable(utf8Byte)
coder.inline('always');
tf = utf8Byte < uint8(128) ;
end

% -------------------------------------------------------------------------
% Return true if the UTF-8 byte is a continuation byte (10XX XXXX)
% -------------------------------------------------------------------------
function tf = isUTF8ContinuationByte(utf8Byte)
coder.inline('always');
tf =  utf8Byte >= uint8(128) && utf8Byte < uint8(192);
end

% -------------------------------------------------------------------------
% Return true if byte is the start of a multi-byte UTF-8 character.
% -------------------------------------------------------------------------
function tf = isStartOfUTF8MultiByteCharacter(utf8Byte)
coder.inline('always');
tf = utf8Byte >= uint8(192) && utf8Byte <= uint8(252);
end

% -------------------------------------------------------------------------
% Return the number of bytes in a multi-byte UTF-8 character by inspecting
% the starting byte of the sequence.
% -------------------------------------------------------------------------
function n = numBytesInSequence(utf8Byte)
coder.inline('always');
n = 1;
while bitand(bitshift(uint8(utf8Byte),n),uint8(128))
    n = n + 1; % tells us how many bytes are in the multi-byte char
end
assert(n<7);  % invalid UTF-8 start byte
end

% -------------------------------------------------------------------------
% Null-terminate a string.
% -------------------------------------------------------------------------
function strout = nullTerminateString(strin)
coder.inline('always');
strout = [strin uint8(0)];
end
   
