function [ utilityLayerFunctions, utilityHistory, utilityAccessCosts, utilityTimeConstraints, utilityAccessCodesMat, utilityPrereqs, utilityBaseLayers, utilityForms, incomeForms, nExpected, hardSlotCountYN ] = createUtilityLayers(locations, modelParameters, demographicVariables )
%createUtilityLayers defines the different income/utility layers (and the
%functions that generate them)

%utility layers are described in this model by:
% 
% i) a function used to generate a utility value, utilityLayerFunctions
% ii) a set of particular codes corresponding to access requirements to use 
% this layer, utilityAccessCodesMat
% iii) a vector of costs associated with each of those codes,
% utilityAccessCosts, and
% iv) a time constraint explaining the fraction of an agent's time consumed 
% by accessing that particular layer, utilityTimeConstraints

% additionally, the estimation of utility is likely to require in most
% applications:
%
% v) a 'base' trajectory for each utility layer over time, that is modified
% by the utility function, utilityBaseLayers
% vi) a stored value of the realized utility value at each point in time
% and space, utilityHistory
% vii) a relationship matrix describing which layers must previously have
% been accessed in order to access a layer, utilityPrereqs
% viii) an identification of the expected occupancy of the layer for which
% utility levels are defined, nExpected
% ix) a flag for whether the expected number can be exceeded or not,
% hardSlotCountYN
% x) a flag differentiating the form of utility generated (against which
% agents may have heterogeneous preferences), utilityForm
% xi) a binary version of the above identifying income as a utility form

%all of these variables are generated here.

%%%%%%%%%%%%%%%%%%%%%%%
%%utilityLayerFunctions
%%%%%%%%%%%%%%%%%%%%%%%
%in the sample below, individual layer functions are defined as anonymous functions
%of x, y, t (timestep), and n (number of agents occupying the layer).  any
%additional arguments can be fed by varargin.  the key constraint of the
%anonymous function is that whatever is input must be executable in a
%single line of code - if the structure for the layer is more complicated,
%one must either export some of the calculation to an intermediate variable
%that can be fed to a single-line version of the layer function OR revisit
%this anonymous function structure.
utilityLayerFunctions{1,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{2,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer
utilityLayerFunctions{3,1} = @(x, y, t, n, varargin) varargin{1};   %some income layer


%%%%%%%%%%%%%%%%%%%%%%%
%%utilityHistory
%%%%%%%%%%%%%%%%%%%%%%%
leadTime = modelParameters.spinupTime;
timeSteps = modelParameters.numCycles * modelParameters.cycleLength; 
utilityHistory = zeros(length(locations),length(utilityLayerFunctions),timeSteps+leadTime);

%%%%%%%%%%%%%%%%%%%%%%%
%%utilityBaseLayers
%%%%%%%%%%%%%%%%%%%%%%%
utilityBaseLayers = -9999 * ones(length(locations),length(utilityLayerFunctions),timeSteps);

%utilityBaseLayers has dimensions of (location, activity, time)

%Below a silly example that makes layer 1 variable over time
utilityBaseLayers(locations.AdminUnit2 > 30, 1,1:timeSteps/3) = 700000;
utilityBaseLayers(locations.AdminUnit2 > 30, 1,timeSteps/3:end) = 0;
utilityBaseLayers(locations.AdminUnit2  <= 30, 1,1:timeSteps/3) = 0;
utilityBaseLayers(locations.AdminUnit2 <= 30, 1,timeSteps/3:end) = 700000;

utilityBaseLayers(locations.AdminUnit2 > 30, 2,:) = 50000;
utilityBaseLayers(locations.AdminUnit2 <= 30, 2,:) = 200000;

utilityBaseLayers(locations.AdminUnit2 > 30, 3,:) = 10000;
utilityBaseLayers(locations.AdminUnit2 <= 30, 3,:) = 10000;

%%%%%%%%%%%%%%%%%%%%%%%
%%utilityAccessCosts
%%%%%%%%%%%%%%%%%%%%%%%
%define the cost of access for utility layers ... payments may provide
%access to different locations (i.e., a license within a state or country)
%or to different layers (i.e., training and certification in related
%fields, or capital investment in related tools, etc.)  

%Dimensions: n x 2, where n is the number of different costs, and the 2
%columns are for the ID and the value

utilityAccessCosts = zeros(length(utilityLayerFunctions),2);

%placeholders as examples
utilityAccessCosts = ...
    [1 1223; %some fee identified with ID 1 is 1223
    ]; 

%%%%%%%%%%%%%%%%%%%%%%%
%%utilityAccessCodesMat
%%%%%%%%%%%%%%%%%%%%%%%

%Dimensions: n x m x k, where n is the number of different costs, m is the
%number of different utility layers, and k is the number of locations
utilityAccessCodesMat = false(size(utilityAccessCosts,1),length(utilityLayerFunctions),length(locations));

%in some way, estimate the number of agents you expect to be occupying a
%particular slot, as well as whether there are a fixed number of slots
%(i.e., jobs) or not (i.e., free entry to that layer).  By default these
%are all set to 0
nExpected = zeros(length(locations),length(utilityLayerFunctions));
hardSlotCountYN = false(size(nExpected));

%nExpected(isnan(nExpected)) = 0;
%nExpected(isinf(nExpected)) = 0;

%utility layers may be income, use value, etc.  identify what form of
%utility it is, so that they get added and weighted appropriately in
%calculation.  BY DEFAULT, '1' is income.  THE NUMBER IN UTILITY FORMS
%CORRESPONDS WITH THE ELEMENT IN THE AGENT'S B LIST.
utilityForms = zeros(length(utilityLayerFunctions),1);

%Utility form values correspond to the list of utility coefficients in
%agent utility functions (i.e., numbered 1 to n) ... in null case, all are
%income (same coefficient)
utilityForms(1:length(utilityLayerFunctions)) = 1;

%Income form is either 0 or 1 (with 1 meaning income)
incomeForms = utilityForms == 1;

%specify the fraction of time for each period in a cycle that a layer
%consumes (this example using a year with 4 periods)
utilityTimeConstraints = ...
    [1 0.5 0.25 0.25 0.5; %accessing layer 1 is a 25% FTE commitment
    2 0.5 0.25 0.25 0.5; %accessing layer 2 is a 50% FTE commitment
    3 0.5 0.75 0.75 0]; %accessing layer 3 is a 50% FTE commitment



%define linkages between layers (such as where different layers represent
%progressive investment in a particular line of utility (e.g., farmland)
utilityPrereqs = zeros(size(utilityTimeConstraints,1));
%let the 2nd Quartile require the 1st, the 3rd require 2nd and 1st, and 4th
%require 1st, 2nd, and 3rd for every layer source
% for indexI = 4:4:size(utilityTimeConstraints,1)
%    utilityPrereqs(indexI, indexI-3:indexI-1) = 1; 
%    utilityPrereqs(indexI-1, indexI-3:indexI-2) = 1; 
%    utilityPrereqs(indexI-2, indexI-3) = 1; 
% end

%each layer 'requires' itself
utilityPrereqs = utilityPrereqs + eye(size(utilityTimeConstraints,1));
utilityPrereqs = sparse(utilityPrereqs);

%with these linkages in place, need to account for the fact that in the
%model, any agent occupying Q4 of something will automatically occupy Q1,
%Q2, Q3, but at present the values nExpected don't account for this.  Thus,
%nExpected for Q1 needs to add in Q2-4, for Q2 needs to add in Q3-4, etc.
%More generally, all 'expected' values need to be adjusted up to allow for
%all things that rely on them.  This is because of a difference between how
%the model interprets layers (occupying Q4 means occupying Q4 + all
%pre-requisites) and the input data (occupying Q4 means only occupying Q4)
tempExpected = zeros(size(nExpected));

for indexI = 1:size(nExpected,2)
   tempExpected(:,indexI) = sum(nExpected(:,utilityPrereqs(:,indexI) > 0),2); 
end
nExpected = tempExpected;

%%% OTHER EXAMPLE CODE BELOW HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
