%ConsoleWaitBar Display a progress bar in the Console Window.
%
%   WB = vision.internal.ConsoleWaitBar(CAPACITY) creates a ConsoleWaitBar
%   object with CAPACITY representing the total number of iterations for
%   the progress to be complete. Use start(WB) to start displaying the wait
%   bar. Use update(WB) to increment the internal count in a loop.
%
%   ConsoleWaitBar methods:
%
%     start(WB)         Start timing and printing the progress.
%
%     update(WB,ITERS)  Increment the progress counter by ITERS
%                       iterations. If ITERS is omitted, its value is
%                       assumed to be 1.
%
%     refresh(WB)       Force refresh the display of the wait bar. The
%                       display is normally refreshed at regular
%                       intervals specified by the "DisplayPeriod"
%                       parameter. Call this method to force refresh
%                       instead.
%
%     finish(WB)        Stop counting progress and displaying the wait
%                       bar. finish(WB) is called by the wait bar once
%                       the progress is complete, after enough calls to
%                       update(WB). Call this method if you wish to end
%                       the wait bar before progress is complete.
%
%   WB = vision.internal.ConsoleWaitBar(___,Name,Value,...) specifies
%   parameters to customize the wait bar. Parameters include:
%
%     "DisplayPeriod"       Time in seconds between each refresh of the
%                           display or the string "asap". If "asap" is
%                           specified, the wait bar is refreshed in the
%                           Command Window as soon as the update(WB) method
%                           is called.
%
%                           Default: 1.0
%
%     "BarLength"           Length of the wait bar in character increments.
%
%                           Default: 50
%
%     "PrintElapsedTime"    Boolean specifying whether to print the time
%                           elapsed since the wait bar started tracking
%                           progress.
%
%                           Default: 0 (false)
%
%     "PrintRemainingTime"  Boolean specifying whether to print the
%                           estimated time remaining until progress is
%                           complete.
%
%                           Default: 0 (false)
%
%     "Verbose"             Set this parameter to 0 (false) to not print
%                           the wait bar in the Command Window.
%
%                           Default: 1 (true)
%
%   Example 1 - Print a progress bar to the command window
%   ------------------------------------------------------
%     n = 200;
%     A = 500;
%     a = zeros(n);
%     wb = vision.internal.ConsoleWaitBar(n);
%     wb.start();
%     for i = 1:n
%         wb.update();
%         a(i) = max(abs(eig(rand(A))));
%     end
%
%   Example 2 - Customize the display of the progress bar
%   -----------------------------------------------------
%     n = 200;
%     A = 500;
%     a = zeros(n);
%     wb = vision.internal.ConsoleWaitBar(n, ...
%         'PrintElapsedTime',1,'PrintRemainingTime',1, ...
%         'DisplayPeriod','asap','BarLength',100);
%     wb.start();
%     for i = 1:n
%         wb.update();
%         a(i) = max(abs(eig(rand(A))));
%     end
%
%   Example 3 - Print a progress bar to the command window in parallel
%   ------------------------------------------------------------------
%     % Define algorithm parameters.
%     n = 200;
%     A = 500;
%     a = zeros(n);
% 
%     % Make sure the parallel pool is started *before* calling start().
%     parpool;
% 
%     % Create the wait bar object
%     wb = vision.internal.ConsoleWaitBar(n, ...
%         'PrintElapsedTime',1, ...
%         'PrintRemainingTime',1);
% 
%     % Create a DataQueue to send progress from the workers back to the client.
%     queue = parallel.pool.DataQueue;
%     afterEach(queue, @(~) wb.update());
% 
%     % The wait bar will stop printing once update() has been called enough
%     % times to reach the maximum iteration count (wb.Progress = 1). You can
%     % also force the end of the printing operation with finish().
%     c = onCleanup(@() wb.finish());
% 
%     % Start printing. Once start() has been called, nothing else should be
%     % printing to the Command Window except the wait bar object.
%     wb.start();
% 
%     % Run code in parallel.
%     parfor i = 1:n
%         % Send progress back to the client
%         send(queue,i);
%         a(i) = max(abs(eig(rand(A))));
%     end
%
%   See also vision.internal.MessagePrinter.

%   Copyright 2017 The MathWorks, Inc.

classdef ConsoleWaitBar < handle
    properties (SetAccess=protected)
        %DisplayPeriod Period in seconds between each refresh of the display.
        DisplayPeriod
        
        %BarLength Number of spaces used to print to wait bar.
        BarLength
        
        %Progress Progress of the operation between 0.0 and 1.0.
        Progress
        
        %Running Boolean indicating whether the wait bar is tracking progress.
        Running
    end
    
    properties (Hidden, SetAccess=protected)
        CompletedIterations
        NumberOfIterations
        DataQueue
        Timer
        Verbose
        Printer
        StartTime
        PrintElapsedTime
        PrintRemainingTime
        PreviousMessageLength
    end
    
    methods
        %------------------------------------------------------------------
        function obj = ConsoleWaitBar(varargin)
            %ConsoleWaitBar Class constructor.
            narginchk(1,Inf);
            
            parser = inputParser();
            parser.FunctionName = mfilename;
            
            % capacity
            validateNumberOfIterations = @(x) validateattributes(x, ...
                {'numeric'}, ...
                {'real','nonsparse','nonempty','finite'}, ...
                mfilename,'capacity',1);
            parser.addRequired('capacity',validateNumberOfIterations);
            
            % DisplayPeriod
            validateDisplayPeriod = @(x) validateattributes(x, ...
                {'numeric','string','char'}, ...
                {'nonsparse'}, ...
                mfilename,'DisplayPeriod');
            validateDisplayPeriodNumeric = @(x) validateattributes(x, ...
                {'numeric'}, ...
                {'real','nonsparse','finite','>=',0.001}, ...
                mfilename,'DisplayPeriod');
            validDisplayPeriodStrings = {'asap'};
            defaultDisplayPeriod = 1;
            parser.addParameter('DisplayPeriod', ...
                defaultDisplayPeriod, ...
                validateDisplayPeriod);
            
            % BarLength
            validateBarLength = @(x) validateattributes(x, ...
                {'numeric'}, ...
                {'real','nonsparse','nonempty','finite','positive','integer'}, ...
                mfilename,'BarLength');
            defaultBarLength = 50;
            parser.addParameter('BarLength', ...
                defaultBarLength, ...
                validateBarLength);
            
            % Verbose
            defaultVerbose = true;
            parser.addParameter('Verbose', ...
                defaultVerbose, ...
                @(x)vision.internal.inputValidation.validateLogical( ...
                x,'Verbose'));
            
            % PrintElapsedTime
            defaultPrintElapsedTime = false;
            parser.addParameter('PrintElapsedTime', ...
                defaultPrintElapsedTime, ...
                @(x)vision.internal.inputValidation.validateLogical( ...
                x,'PrintElapsedTime'));
            
            % PrintRemainingTime
            defaultPrintRemainingTime = false;
            parser.addParameter('PrintRemainingTime', ...
                defaultPrintRemainingTime, ...
                @(x)vision.internal.inputValidation.validateLogical( ...
                x,'PrintRemainingTime'));
            
            parser.parse(varargin{:});
            inputs = parser.Results;
            
            obj.NumberOfIterations = inputs.capacity;
            if isnumeric(inputs.DisplayPeriod)
                validateDisplayPeriodNumeric(inputs.DisplayPeriod);
                obj.DisplayPeriod = inputs.DisplayPeriod;
            else
                validatestring(inputs.DisplayPeriod, ...
                    validDisplayPeriodStrings);
                obj.DisplayPeriod = [];
            end
            obj.BarLength = inputs.BarLength;
            obj.Verbose = logical(inputs.Verbose);
            obj.PrintElapsedTime = logical(inputs.PrintElapsedTime);
            obj.PrintRemainingTime = logical(inputs.PrintRemainingTime);
            obj.Printer = vision.internal.MessagePrinter.configure(obj.Verbose);
            obj.reset();
        end
        
        %------------------------------------------------------------------
        function delete(obj)
            %delete Class destructor.
            if ~isempty(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
                obj.Timer = [];
            end
        end
        
        %------------------------------------------------------------------
        function start(obj)
            %start Start tracking progress and display wait bar.
            if obj.Running
                return
            end
            obj.reset();
            obj.Running = true;
            obj.StartTime = tic;
            if ~isempty(obj.DisplayPeriod)
                obj.Timer = timer( ...
                    'ExecutionMode','fixedSpacing', ...
                    'Period',obj.DisplayPeriod, ...
                    'TimerFcn',@(~,~)obj.refresh(), ...
                    'ErrorFcn',@(~,~)obj.reset(), ...
                    'ObjectVisibility','off');
                start(obj.Timer);
            end
        end
        
        %------------------------------------------------------------------
        function stop(obj)
            %stop Stop tracking progress and terminate display of wait bar.
            obj.CompletedIterations = obj.NumberOfIterations;
            obj.Progress = 1;
            obj.print();
            if ~isempty(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
                obj.Timer = [];
            end
            obj.Running = false;
        end
        
        %------------------------------------------------------------------
        function update(obj,iters)
            %update Update the count of completed iterations.
            if ~obj.Running
                return
            end
            if (nargin < 2)
                iters = 1;
            end
            obj.CompletedIterations = obj.CompletedIterations + iters;
            obj.Progress = obj.CompletedIterations / obj.NumberOfIterations;
            if isempty(obj.Timer)
                obj.refresh();
            end
        end
        
        %------------------------------------------------------------------
        function refresh(obj)
            %refresh Refresh display of wait bar regardless of internal timer.
            if ~obj.Running
                return
            end
            if (obj.Progress >= 1)
                obj.stop();
                return
            end
            obj.print();
        end
        
        %------------------------------------------------------------------
        function reset(obj)
            %reset Reset progress to zero.
            obj.CompletedIterations = 0;
            obj.Progress = 0;
            if ~isempty(obj.Timer)
                stop(obj.Timer);
            end
            obj.Running = false;
            obj.PreviousMessageLength = 0;
            obj.StartTime = 0;
        end
    end
    
    methods (Hidden,Access=protected)
        %------------------------------------------------------------------
        function print(obj)
            %print Print updated state of wait bar.
            numBlacks = floor(obj.Progress * obj.BarLength);
            numWhites = obj.BarLength - numBlacks;
            bar = ['[' repmat('=',1,numBlacks) repmat(' ',1,numWhites) ']'];
            newMessage = sprintf('%s %3d%%%%\n', bar, floor(100 * obj.Progress));
            str = [repmat('\b',1,obj.PreviousMessageLength) newMessage];
            obj.PreviousMessageLength = numel(strrep(newMessage,'%%','%'));
            obj.Printer.printDoNotEscapePercent(str);
            obj.printElapsedTime();
            obj.printRemainingTime();
        end
        
        %------------------------------------------------------------------
        function printElapsedTime(obj)
            %printElapsedTime Print elapsed time in HH:MM:SS format.
            if ~obj.PrintElapsedTime
                return
            end
            elapsedTime = toc(obj.StartTime);
            [h,m,s] = obj.secondsToHMS(elapsedTime);
            str = getString(message('vision:ConsoleWaitBar:ElapsedTime'));
            str = sprintf('%s: %02d:%02d:%02d\n',str,h,m,s);
            obj.PreviousMessageLength = obj.PreviousMessageLength + numel(str);
            obj.Printer.printDoNotEscapePercent(str);
        end
        
        %------------------------------------------------------------------
        function printRemainingTime(obj)
            %printRemainingTime Print estimated remaining time in HH:MM:SS format.
            if ~obj.PrintRemainingTime
                return
            end
            elapsedTime = toc(obj.StartTime);
            remainingTime = elapsedTime * (1 - obj.Progress) / obj.Progress;
            str = getString(message('vision:ConsoleWaitBar:RemainingTime'));
            if isfinite(remainingTime)
                [h,m,s] = obj.secondsToHMS(remainingTime);
                str = sprintf('%s: %02d:%02d:%02d\n',str,h,m,s);
            else
                str = sprintf('%s: ...\n',str);
            end
            obj.PreviousMessageLength = obj.PreviousMessageLength + numel(str);
            obj.Printer.printDoNotEscapePercent(str);
        end
    end
    
    methods (Hidden,Static)
        %------------------------------------------------------------------
        function [h,m,s] = secondsToHMS(timeInSeconds)
            %secondsToHMS Convert seconds to hours, minutes, and seconds.
            h = floor(timeInSeconds / 3600);
            timeInSeconds = timeInSeconds - h * 3600;
            m = floor(timeInSeconds / 60);
            s = floor(timeInSeconds - m * 60);
        end
    end
end
