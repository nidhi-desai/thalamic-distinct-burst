function EffectOf_TCspikeOnEPSP_Interneuron()
%% Description
% This code runs simulations for Section 3.7 figure 9h.
% It simulates the EPSP amplitude (mV) change from the resting potential in a interneuron cell
% as a result of a thalamocortical spike simulated at different synaptic release probabilities.
% by Nidhi Desai

%% Adding for loop for all the release probability values
resProbAfterLatency = load('resProbAfterLatency.mat'); % input release probability values shown in Figure 9B
simulationINresProb = resProbAfterLatency;
temp = zeros(size(resProbAfterLatency.resProb,1),1);
folderName = 'Results';
cd (folderName);
fileName = 'TC-INcellModel_diffResProbEffect';
exportToPPTX('new', fileName); 
exportToPPTX('saveandclose', fileName);

for r = 408:size(resProbAfterLatency.resProb,1)
    %% Making master set of equations
     eqns = {'dV/dt=(@current + iAppliedCurrent(t))/Cm';
      'iAppliedCurrent2 = 0';
      'iAppliedCurrent(t) =  0*(t<1000) + iAppliedCurrent2*(t>1000 && t<1002) + 0*(t>1002)'; 
      'Cm = 1';    % uF/cm^2
      'spike_threshold = -25';
      'monitor V.spikes(spike_threshold, 1)';
      'vIC = -68';    % mV
      'vNoiseIC = 50'; % mV
      'V(0) = -60'}; 

    %% 2. Assemble Cortex Model  
    % IN cells:
    specification = [];
    specification.populations(1).name = 'IN';
    specification.populations(1).size = 1;
    specification.populations(1).equations = eqns; 
    specification.populations(1).mechanism_list = {...
        'iAppliedCurrent',...
        'iLeak_IN_JB12',...
        'iNa_IN_JB12',...
        'iK_IN_JB12'};

    %% 3. Assemble Thalamic Model  
    specification.populations(2).name = 'TC';
    specification.populations(2).size = 1;
    specification.populations(2).equations = eqns;
    specification.populations(2).mechanism_list = {...
        'iAppliedCurrent',...
        'iNa_TC_AS17',...
        'iK_TC_AS17',...
        'iLeak_TC_AS17',...
        'CaBuffer_TC_AS17',...
        'iT_TC_AS17',...
        'iH_TC_AS17'};

    %% 4. Thalamo-cortical Connections
    specification.connections(1).direction = 'IN<-TC';
    specification.connections(1).mechanism_list = {'iAMPA_IN_TC_modified_start_res0'};

    %% 1. Define simulation parameters
    % While DynaSim uses a default `dt` of 0.01 ms, we must specify ours explicitly
    % since `dt` is actually used to construct our model directly.
    dt = 0.01; % in milliseconds
    vary = {'TC', 'iAppliedCurrent2', 40;
        'IN<-TC', 'resProb0', double(resProbAfterLatency.resProb(r))};

    %% 2. Run the simulation
    data = dsSimulate(specification,'tspan',[0 2000],'vary',vary,'solver','euler','verbose_flag',1);
    rmdir('solve', 's');
    
    %% 3. Plot the results of the simulation 
%     dsPlot(data,'ylim',[-100 50]);
    h = figure;
    s1 = subplot(2,2,1); plot(data.time, data.TC_V, 'b'); title('TC\_Vol');
    s2 = subplot(2,2,2); plot(data.time, data.IN_V, 'r'); title('IN\_Vol');
    s3 = subplot(2,2,3); plot(data.time, data.IN_TC_iAMPA_IN_TC_modified_res);
    linkaxes([s1, s2, s3], 'x');
    xlim([950, 1200]);
    suptitle({strcat('i= ', num2str(resProbAfterLatency.i(r)),...
            '; j= ', num2str(resProbAfterLatency.j(r)))});
    exportToPPTX('open', fileName); 
    exportToPPTX('addslide');
    exportToPPTX('addpicture', h);
    exportToPPTX('saveandclose',fileName);
    close(h); 
    
    % Save required output data
    indx999 = find(data.time == 999);
    indx1000 = find(data.time == 1000);
    indx1200 = find(data.time == 1200);
    shortVol = data.IN_V(indx1000:indx1200);
    temp(r) = max(shortVol) - data.IN_V(indx999);
    
end
simulationINresProb.maxVolChange = temp;

%% Plotting boxplot for IN max voltage as a result of TC spike at different release probability
% 24th January 2021
load('C:\Users\Nidhi Desai\OneDrive - University of North Carolina at Chapel Hill\Carmen_Manuscript_shared_drive_local_copy\Final_codes_used_for_Manuscript\Probability release model\Results\simulationINresProb.mat');
T = table();
T.maxVolChange = simulationINresProb.maxVolChangeINsimulation;
T.cellOrder = simulationINresProb.order;
T.sensorySystem = simulationINresProb.sensory;
writetable(T, 'IN_effectOfResProb.csv');

scatter(simulationINresProb.resProb, simulationINresProb.maxVolChangeINsimulation, '.', 'b');
ylabel("IN maxVolChange"); xlabel("release probability");
ylim([0,5]);



