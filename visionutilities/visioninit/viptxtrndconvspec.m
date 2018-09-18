function [convSpec, numPercentAndMinWidthSave, minFieldWidth, precision] = ...
    viptxtrndconvspec(theText,calledFromBlock)
% VIPTXTRNDCONVSPEC Helper function to determine the conversion specification. 
% This is called from the mask helper function vipblktxtrnd.    

    match = strfind(theText, '%');
    numPercentAndMinWidth = length(match);
    numPercentAndMinWidthSave = numPercentAndMinWidth;
    minFieldWidth = 0;
    currPrecision = '';
    precision = 0;
    indx = 1;
    if calledFromBlock
        paramOrPropStr = 'parameter';
        blockOrCompStr = 'Insert Text Block';
    else
        paramOrPropStr = 'property';
        blockOrCompStr = 'viplib.inserttext component';
    end
    
    while (numPercentAndMinWidth)
        currMinFieldWidth = '';        
        offset = 1;isValid = false;
        sizeModifierSpecified = false;
        currCharIsPoint = false; %#ok<NASGU>
        currCharIsPrecision = false;        
        currCharIsMinFieldWidth = false;
        doneCheckingFlag = false;
        doneCheckingMinFieldWidth = false;
        donecheckingPoint = false;
        doneCheckingPrecision= false;
        checkForPercent = true;
        while(1)     
            curr_char = theText(match(indx)+offset);
            if (curr_char == '%') && (checkForPercent)
                %% This means we have '%%', where the first % is the escape
                %% character to print '%'. 
                conversion(indx) = '%';
                isValid = true; 
                numPercentAndMinWidth = numPercentAndMinWidth-1;
                numPercentAndMinWidthSave = numPercentAndMinWidthSave-1;
                indx = indx+1;
                conversion(indx) = '%'; %% just to fill up empty space. 
                break;
            else
                checkForPercent = false;
                if (~doneCheckingFlag && ((curr_char == '-') || ...
                        (curr_char == '#') || (curr_char == '0') || ...
                        (curr_char == ' ') || (curr_char == '+')))
                    currCharIsFlag = true;
                    offset = offset+1;
                else
                    currCharIsFlag = false;
                    doneCheckingFlag = true;
                end
                if (~currCharIsFlag)
                    %% fix('0') = 48, fix('9') = 57
                    if (~doneCheckingMinFieldWidth && (((curr_char >= '0') ...
                            && (curr_char <= '9')))) 
                        currMinFieldWidth = [currMinFieldWidth curr_char];
                        currCharIsMinFieldWidth = true;
                        offset = offset+1;
                    else
                        if (currCharIsMinFieldWidth)
                            minFieldWidth = minFieldWidth + str2num(currMinFieldWidth);
                        end
                        currCharIsMinFieldWidth = false;
                        doneCheckingMinFieldWidth = true;
                        
                    end                
                    if (~currCharIsMinFieldWidth)  %  fix('.') = 46
                        if (~donecheckingPoint) && (curr_char == '.') 
                            currCharIsPoint = true;
                            offset = offset + 1;                        
                        else
                            currCharIsPoint = false;
                            donecheckingPoint = true;
                        end
                        if (~currCharIsPoint)
                            if ~doneCheckingPrecision && ((curr_char >= '0') && (curr_char <= '9'))
                                currCharIsPrecision = true;
                                currPrecision = [currPrecision curr_char];
                                offset = offset+1;
                            else
                                if (currCharIsPrecision)
                                    precision = precision + str2num(currPrecision);
                                end
                                currCharIsPrecision = false;
                                doneCheckingPrecision = true;
                                currPrecision = '';
                            end  
                            if (~currCharIsPrecision)
                                %% fix('c') = 99, fix('x') = 120, fix('X') = 88
                                %% fix('L') =76 , fix('E') = 69,fix('G') = 71
                                if (((curr_char >= 'c') && (curr_char <= 'x')) || ...
                                     (curr_char == 'E') || (curr_char == 'G') || ...
                                     (curr_char == 'L') || (curr_char == 'X'))
                                    isValid = true;
                                    c_match_l = strfind(curr_char,'l');
                                    c_match_h = strfind(curr_char,'h');
                                    c_match_L = strfind(curr_char,'L');
                                    if (~sizeModifierSpecified && (~isempty(c_match_l)||~isempty(c_match_h)||~isempty(c_match_L)))
                                        sizeModifierSpecified = true;
                                        offset = offset+1;
                                        continue;
                                    end
                                    c_match = strfind(curr_char,'d');
                                    if (~isempty(c_match))
                                        conversion(indx) = 'd';
                                        break;
                                    end
                                    c_match = strfind(curr_char,'i');
                                    if (~isempty(c_match))
                                        conversion(indx) = 'i';
                                        break;
                                    end
                                    c_match = strfind(curr_char,'u');
                                    if (~isempty(c_match))
                                        conversion(indx) = 'u';
                                        break;
                                    end
                                    c_match = strfind(curr_char,'f');
                                    if (~isempty(c_match))
                                        conversion(indx) = 'f';
                                        break;
                                    end
                                    c_match = strfind(curr_char,'c');
                                    if (~isempty(c_match))
                                        conversion(indx) = 'c';
                                        break;
                                    end
                                    c_match = strfind(curr_char,'s');
                                    if (~isempty(c_match))
                                        conversion(indx) = 's';
                                        break;
                                    end
                                    c_match = strfind(curr_char,'o');
                                    if (~isempty(c_match))
                                        conversion(indx) = 'o';
                                        break;
                                    end
                                    c_match_x = strfind(curr_char,'x');
                                    c_match_X = strfind(curr_char,'X');
                                    if (~isempty(c_match_x)) || (~isempty(c_match_X))
                                        conversion(indx) = 'x';
                                        break;
                                    end
                                    c_match_e = strfind(curr_char,'e');
                                    c_match_E = strfind(curr_char,'E');
                                    if (~isempty(c_match_e)) || (~isempty(c_match_E))
                                        conversion(indx) = 'e';
                                        break;
                                    end
                                    c_match_g = strfind(curr_char,'g');
                                    c_match_G = strfind(curr_char,'G');
                                    if (~isempty(c_match_g)) || (~isempty(c_match_G))
                                        conversion(indx) = 'g';
                                        break;
                                    end
                                    isValid = false;
                                    error(message('vision:viptxtrndconvspec:invalidConvLetter1', curr_char, paramOrPropStr, blockOrCompStr));
                                    break;
                                else
                                    isValid = false;
                                    error(message('vision:viptxtrndconvspec:invalidConvLetter2', curr_char, paramOrPropStr, blockOrCompStr));
                                    break;
                                end
                            end
                        end
                    end
                end
            end   
        end
        if (~isValid)
              error(message('vision:viptxtrndconvspec:invalidConvLetter3', paramOrPropStr, blockOrCompStr));            
        end   
        indx = indx+1;
        numPercentAndMinWidth = numPercentAndMinWidth-1;        
    end
    if ~isempty(strfind(conversion,'%'))
        sorted = sort(conversion);
        i = 1;
        while (i <= length(sorted)) && (sorted(i) == '%')
            numPercentAndMinWidthSave = numPercentAndMinWidthSave-1;        
            i = i+2;
        end
        if (i < length(sorted))
            if (sorted(i) ~= max(sorted))
                  error(message('vision:viptxtrndconvspec:invalidConvLetter4', paramOrPropStr, blockOrCompStr));                        
            end
        end
        conversion(1) = sorted(length(sorted));
    else
        if (min(conversion) ~= max(conversion)) 
            % factor out the case when conversion is '%'
            error(message('vision:viptxtrndconvspec:invalidConvLetter4', paramOrPropStr, blockOrCompStr));        
        end
    end
    if ((numPercentAndMinWidthSave > 1) && strcmp(conversion(1),'s'))
        error(message('vision:viptxtrndconvspec:invalidConvLetter5', paramOrPropStr, blockOrCompStr, '%s'));
    end
    convSpec = conversion(1);

%----------------------------------------------------------