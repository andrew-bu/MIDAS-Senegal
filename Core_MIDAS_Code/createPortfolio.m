function portfolio = createPortfolio(portfolio, layers, constraints, prereqs,pAdd, accesscodes, utilityCosts, agent, selectable)
%createPortfolio draws a random portfolio of utility layers that fit the current time constraint

%Steps:
%1a. If portfolio specified, identify if any elements are aspirational (i.e. not selectable)
%1b. If there are aspirational elements, fill out high-fidelity portfolio with prereqs that are selectable
%1c. With time remaining, fill out remaining high-fidelity portfolio with other selectable layers
%2. If portfolio not specified, create random portfolio from scratch as
%before
%3. Return high-fidelity portfoliio and aspiration (if applicable)

%Start Test Data
%samplePortfolio = [true; ...
    %true; ...
    %false; ...
    %false; ...
    %false; ...
    %false];

%End Test Data

%start with all the time in the world
timeRemaining = ones(1, size(constraints,2)-1);  %will be as long as the cycle defined for layers

%First check if portfolio is specified. If not, create one at random (original code)
if isempty(portfolio)
    %initialize an empty portfolio
    portfolio = false(1,size(constraints,1));
    
    %while we still have time left and layers that fit
    while(sum(timeRemaining) > 0 && ~isempty(layers))
    
        %draw one of those layers at random and remove it from the set
        randomDraw = ceil(rand()*length(layers));
    
        nextElement = layers(randomDraw);
        layers(randomDraw) = [];
    
        if(~portfolio(nextElement))  %if this one isn't already in the portfolio (e.g., it got drawn in as a prereq in a previous iteration)
            %make a temporary portfolio for consideration

            tempPortfolio = portfolio | prereqs(nextElement,:); %This adds the nextElement plus all other prereqs to 1-dimensional portfolio
        
        
        end
        
            timeUse = sum(constraints(tempPortfolio,2:end),1);
            timeExceedance = sum(sum(timeUse > 1)) > 0;


            %test whether to add it to the portfolio, if it fits
            if(~timeExceedance & rand() < pAdd)
                portfolio = tempPortfolio;

                %remove any that are OBVIOUSLY over the limit, though this won't
                %catch any that have other time constraints tied to prereqs
                timeRemaining = 1 - timeUse;
                layers(sum(constraints(layers,2:end) > timeRemaining,2) > 0) = [];
            end
    end

end 


%Now check if portfolio (either pre-specified or created through this function) has any aspirational elements
samplePortfolio = portfolio';
aspirations = samplePortfolio & ~selectable;

    
%If any elements are aspirations, pick one at random and figure out prereqs
if any(aspirations)
    indAspirations = find(aspirations);
    samplePortfolio(indAspirations) = false;

    %Select one aspiration at random
    if length(indAspirations) > 1
        indexA = randsample(indAspirations,1);
    else
        indexA = indAspirations;
    end
    
    %Add any selectable prereqs to portfolio
    [i,j,s] = find(prereqs); %Indices of layers that are prerequisite for indexA    
    portfolioPrereqs = j(i==indexA);  
    portfolioPrereqs(portfolioPrereqs == indexA) = []; %remove own layer from aspiration's prereqs
           
    if any(portfolioPrereqs)
        samplePortfolio(portfolioPrereqs) = true;       
    end
        
    %If time is exceeded, remove layers one by one    
    timeRemaining = 1 - sum(constraints(samplePortfolio,2:end));    
    while sum(timeRemaining) < 0    
        tempLayers = find(samplePortfolio);    
        samplePortfolio(randsample(tempLayers,1)) = false;    
        timeRemaining = 1 - sum(constraints(samplePortfolio,2:end));    
    end

end

    
%Now, if time still remains and selectable layers are still available, keep filling portfolio    
selectableLayers = selectable & ~samplePortfolio;
    
while sum(timeRemaining) > 0 && any(selectableLayers)    
    indexS = randsample(find(selectableLayers,1),1);    
    samplePortfolio(indexS) = true;    
    timeRemaining = 1 - sum(constraints(samplePortfolio,2:end));    
    selectableLayers(indexS) = false;    
end

end






