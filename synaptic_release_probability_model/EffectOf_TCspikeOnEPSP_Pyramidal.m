function EffectOf_TCspikeOnEPSP_Pyramidal()
%% Description
% This code runs simulations for Section 3.7 figure 9i.
% It simulates the EPSP amplitude (mV) change from the resting potential in a pyramidal cell
% as a result of a thalamocortical spike simulated at different synaptic release probabilities.
% by Nidhi Desai

%% Adding for loop for all the release probability values
resProbAfterLatency = load('resProbAfterLatency.mat'); % input release probability values shown in Figure 9B
simulationPyCresProb = resProbAfterLatency;
temp = zeros(size(resProbAfterLatency.resProb,1),1);
folderName = 'Results';
cd (folderName);
fileName = 'TC-PYdr_cellModel_diffResProbEffect';
exportToPPTX('new', fileName); 
exportToPPTX('saveandclose', fileName);

for r = 1:size(resProbAfterLatency.resProb,1)
    %% Make master equations and initialize
    eqns={
      'dV/dt=(@current + iAppliedCurrent(t))/Cm'
      'iAppliedCurrent2 = 0';
      'iAppliedCurrent(t) =  0*(t<1000) + iAppliedCurrent2*(t>1000 && t<1002) + 0*(t>1002)'; 
      'Cm = 1'    % uF/cm^2
      'spike_threshold = -25'
      'monitor V.spikes(spike_threshold, 1)'
      'vIC = -68'    % mV
      'vNoiseIC = 50' % mV
      'V(0) = -60'
    }; 

    %% Assemble Pyr Model  
    % PyC cell
    specification = [];
    specification.populations(1).name='PYdr';
    specification.populations(1).size=1;
    specification.populations(1).equations=eqns;
    specification.populations(1).mechanism_list={...       
        'CaBuffer_PYdr_JB12',...
        'iHVA_PYdr_JB12',...
        'iKCa_PYdr_JB12',...
        'iNaP_PYdr_JB12',...
        'iAR_PYdr_JB12',...
        };

    specification.populations(2).name='PYso';
    specification.populations(2).size=1;
    specification.populations(2).equations=eqns;
    specification.populations(2).mechanism_list={...    
        'iLeak_PYso_JB12',...
        'iNa_PYso_JB12',...
        'iK_PYso_JB12',...
        'iA_PYso_JB12',...
        'iKS_PYso_JB12',...
        };

    specification.connections(1).direction='PYso<-PYdr';
    specification.connections(1).mechanism_list={...
        'iCOM_PYso_PYdr_JB12',...
        'iNaCurrs_PYso_PYdr_JB12',...
        };
    specification.connections(2).direction='PYdr<-PYso';
    specification.connections(2).mechanism_list={...
        'iCOM_PYdr_PYso_JB12',...
        'iAMPA_PYdr_PYso_JB12',...
        'iNMDA_PYdr_PYso_JB12'};

    %% Assemble Thalamic Model 
    specification.populations(3).name='TC';
    specification.populations(3).size=1;
    specification.populations(3).equations=eqns;
    specification.populations(3).mechanism_list={...
        'iAppliedCurrent',...
        'iNa_TC_AS17',...
        'iK_TC_AS17',...
        'iLeak_TC_AS17',...
        'CaBuffer_TC_AS17',...
        'iT_TC_AS17',...
        'iH_TC_AS17'};

    %% Thalamo-cortical Connections
    specification.connections(3).direction='PYdr<-TC';
    specification.connections(3).mechanism_list={'iAMPA_PYdr_TC_modified_start_res0'};

    %% Define simulation parameters
    dt = 0.01; % in milliseconds
    vary = {'TC', 'iAppliedCurrent2', 40;
        'PYdr<-TC', 'resProb0', double(resProbAfterLatency.resProb(r))};

    %% Run the simulation
    data = dsSimulate(specification,'tspan',[0 2000],'vary',vary,'solver','euler','verbose_flag',1);
    rmdir('solve', 's');
    
    %% 3. Plot the results of the simulation 
    h = figure;
    s1 = subplot(2,2,1); plot(data.time, data.TC_V, 'b'); title('TC\_Vol');
    s2 = subplot(2,2,2); plot(data.time, data.PYdr_V, 'r'); title('PYdr\_Vol');
    s3 = subplot(2,2,3); plot(data.time, data.PYdr_TC_iAMPA_PYdr_TC_modified_res);
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
    shortVol = data.PYdr_V(indx1000:indx1200);
    temp(r) = max(shortVol) - data.PYdr_V(indx999);
    
end
simulationPyCresProb.maxVolChange = temp;

%% Plotting boxplot for IN max voltage as a result of TC spike at different release probability
T = table();
T.maxVolChange = simulationPyCresProb.maxVolChange;
T.cellOrder = simulationPyCresProb.order;
T.sensorySystem = simulationPyCresProb.sensory;
writetable(T, 'PyC_effectOfResProb.csv');

figure; hold on; scatter(simulationPyCresProb.resProb, simulationPyCresProb.maxVolChange,'.','k');
ylabel("PyC maxVolChange"); xlabel("release probability");
