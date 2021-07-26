function shiftingMinf_Hinf_gT_toSimulateBursts()
%% Description
% This code runs simulations for Section 3.8 figure 10c.
% It simulates and calculates the fraction of inhibitory pulses which would 
% lead a TC cell to burst when applied at increasing frequencies.
% by Nidhi Desai

%% Setting up parameters to vary
gT = [0.15;0.15;...
    0.25;0.25;0.25;...
    0.35;0.35;0.35;0.35;...
    0.5;0.5;0.5;0.5;...
    1];
Vshift = [0;-5;...
    0;-5;-12;...
    0;-5;-12;-15;...
    0;-5;-12;-15;...
    -22];
hyperVolCurrent = 0.8; 

%% Setting up the model - Run evertime before running any simulations in this document
Ne = 1;
hyperpolarStartTime = 500; % ms
hyperpolarStopTime = 1000; % ms
totalSimulationTime = 1500; % ms

eqns = {'dV/dt=(@current + HyperP(t))/Cm';
   % 'hyperVolCurrent = 1'; % Iapp = 1 hyperpolarizes the cell to around -87 mV
    strcat('HyperP(t) = 0*(t<', num2str(hyperpolarStartTime), ')-hyperVolCurrent*(t>',...
    num2str(hyperpolarStartTime), '&& t<', num2str(hyperpolarStopTime), ')+0*(t>', ...
    num2str(totalSimulationTime),')');
    'Cm = 1'; % uF/cm^2
    'spike_threshold = -5'; 
    'V(0) = -60'};

%% Setting model
mechanism_listS = {'iNa_TC_AS17',...
'iK_TC_AS17',...
'iLeak_TC_AS17',...
'iKLeak_TC_CV19',...
'CaBuffer_TC_AS17',...
'iH_TC_CV19',...
'iT_TC_AS17'}; 

specification = [];
specification.populations(1).name = 'Ed';
specification.populations(1).size = Ne;
specification.populations(1).equations = eqns;
specification.populations(1).mechanism_list = mechanism_listS;
specification.populations(1).parameters = {'hyperVolCurrent',hyperVolCurrent};

%% Running simulations
vary = cell(size(Vshift));
for w = 1:size(Vshift,1)
    vary{w,1} = {'Ed', 'gT', gT(w);...
        'Ed', 'Vshift', Vshift(w)};
end
data = dsSimulate(specification,'tspan',[0 2500],'vary',vary,'solver','rk1','verbose_flag',1);    
rmdir('solve', 's');
figure; plot(data.time, data.Ed_V);
xlim([1000, 1200]);

%% Saving burst properties of output from simualtions
simResults = table();
for r = 1:size(Vshift,1)
    burstProp = extractBurstInfo_FromSimulationVoltageOutput(...
    data(r).time, data(r).Ed_V, hyperpolarStartTime, hyperpolarStopTime);
    simResults.gT(r) = gT(r);
    simResults.Vshift(r) = Vshift(r);
    simResults.hyperVolCurrent(r) = hyperVolCurrent;
    simResults.hyperVol(r) = burstProp.hyperVol;
    simResults.numSpks(r) = burstProp.numSpks;
    simResults.latency(r) = burstProp.latency;
end

end