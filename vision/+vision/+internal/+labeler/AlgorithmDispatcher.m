classdef AlgorithmDispatcher < handle
    
    properties   
        % Algorithm An instance of an AutomationAlgorithm.
        Algorithm    
        
        % AlgorithmClass Fullname of algorithm (e.g.
        %                vision.labeler.Foo)
        AlgorithmClass = '';       
        
        % AlgorithmName User defined algorithm name
        AlgorithmName
        
    end
    
    properties(Dependent)
        % Fullpath Returns the current path to the algorithm or the path
        % cached in the repository.
        Fullpath  
               
        % FolderFromRepository Returns the path to folder containing the
        % packaged algorithm, i.e. it returns /path/to if algorithm is in
        % /path/to/+vision/+labeler/foo.m
        FolderFromRepository
    end
    
    methods (Abstract, Static, Hidden)
        %------------------------------------------------------------------
        repo = getRepository()
    end
    
    methods
        %------------------------------------------------------------------
        function configure(this, classname)
            repo = this.getRepository();
            
            this.AlgorithmClass = classname;
            this.AlgorithmName  = repo.getAlgorithmName(classname);
                                 
        end
        
        %------------------------------------------------------------------
        function tf = isAlgorithmOnPath(this)
                                  
            if isempty(this.Fullpath)
                tf = false;
            else
                tf = true;
            end            
        end
        
        %------------------------------------------------------------------
        % Checks validity of Algorithm class. When the algorithm is not
        % valid, a message is returned which can be used by clients to
        % throw exceptions/dialogs.
        %------------------------------------------------------------------
        function [tf,msg] = isAlgorithmValid(this)
            
            metaClass   = meta.class.fromName(this.AlgorithmClass);
            methodList  = metaClass.MethodList;
            methodNames = {methodList.Name};
            
            % Get the constructor meta.method object.
            classStrings = strsplit( this.AlgorithmClass, '.' );
            constructorName = classStrings{end};
            
            constructor = methodList(strcmpi(constructorName,methodNames));
            
            % Expect zero input constructor.
            if isa(constructor,'meta.method') && numel(constructor.InputNames)>0
                tf = false;
                msg = vision.getMessage('vision:labeler:NoArgConstructorNeeded');
            else
                tf = true;
                msg = string.empty();
            end
            
        end
        
        %------------------------------------------------------------------
        % Creates and instance of the algorithm by name. May throw
        % exceptions. Clients responsible for catching.
        %------------------------------------------------------------------
        function instantiate(this)  
            assert(not(isempty(this.AlgorithmClass)), 'Call configure first!');                                                      
            this.Algorithm = eval(this.AlgorithmClass);           
                
        end
        
        %------------------------------------------------------------------
        % Returns the path to the algorithm by calling WHICH.
        %------------------------------------------------------------------
        function p = get.Fullpath(this)
            assert(not(isempty(this.AlgorithmClass)), 'Call configure first!');  
            p = which(this.AlgorithmClass);
        end
        
        %------------------------------------------------------------------
        % Returns the path to the algorithm that is cached in the
        % repository.              
        %------------------------------------------------------------------            
        function p = get.FolderFromRepository(this)
            repo = this.getRepository();
            p = repo.getAlgorithmFolder(this.AlgorithmClass);            
        end
             
    end
end