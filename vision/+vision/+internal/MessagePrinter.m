% This class implements an interface for printing messages based on a
% verbosity flag. 
%
% Example
% -------
%   printer = vision.internal.MessagePrinter.configure(true)
%   printer.print('message');

classdef (HandleCompatible) MessagePrinter
   
    methods(Abstract)
        print(this)
        printMessageNoReturn(this)
        printDoNotEscapePercent(this)
        linebreak(this)
    end
    
    methods (Static)        
        %------------------------------------------------------------------
        % Returns a printer object based on a verbosity flag. When
        % isVerbose is false, the printer object will not print to the
        % command window.
        %
        function printer = configure(isVerbose)
            persistent verbosePrinter nullPrinter
            
            if isempty(verbosePrinter)
                verbosePrinter = vision.internal.VerbosePrinter();
                nullPrinter    = vision.internal.NullPrinter();
            end
            
            if isVerbose
                printer = verbosePrinter;
            else
                printer = nullPrinter;
            end
        end               
        
        %------------------------------------------------------------------
        % Parses for the parameter 'Verbose' and returns a configured
        % printer.
        %
        function isVerbose = parseForVerbose(varargin)
            persistent parser
            if isempty(parser)
                
                parser = inputParser();
                parser.addParameter('Verbose', false);
                parser.KeepUnmatched = true;
                
            end
            
            parser.parse(varargin{:});                        
            
            vision.internal.inputValidation.validateLogical(parser.Results.Verbose, 'Verbose');
            
            isVerbose = logical(parser.Results.Verbose);                       
        end
        
        %------------------------------------------------------------------
        function printer = parseAndConfigure(varargin)
            isVerbose = vision.internal.MessagePrinter.parseForVerbose(varargin{:});
            printer   = vision.internal.MessagePrinter.configure(isVerbose);
        end       
    end
            
    methods              
        %------------------------------------------------------------------
        % Utility function to create hyperlinked commands.
        %
        function cmdstr = makeHyperlink(~, str,cmd)
            if feature('hotlinks')
                cmdstr = sprintf('<a href="matlab:%s">%s</a>',cmd,str);
            else
                % do not print a hyperlink when in nodesktop mode
                cmdstr = sprintf('%s', str);
            end
        end
        
        %------------------------------------------------------------------
        % Print using message ID. Adds linebreak after the message.
        function this = printMessage(this,varargin)                   
            this.printMessageNoReturn(varargin{:});
            this.linebreak;            
        end    
        
    end
end 