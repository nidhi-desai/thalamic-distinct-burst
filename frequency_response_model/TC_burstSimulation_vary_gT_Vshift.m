function [data, AppCurrentTime, hyperpolarStartTime] = TC_burstSimulation_vary_gT_Vshift(gT_temp, Vshift_temp, Iapp, freq) 

hyperpolarStartTime = 1000;
totalSimulationTime = 4500 + hyperpolarStartTime; % ms
hyperpolarFreq = freq; % Hz or spikes/second
timeOfOneCycle = 1000/hyperpolarFreq;
timeOfHyperpolarizingInput = 50; % ms

AppCurrentTime = [hyperpolarStartTime, hyperpolarStartTime + timeOfHyperpolarizingInput];
currentTime = hyperpolarStartTime + timeOfOneCycle;
while currentTime <= totalSimulationTime - 500
    AppCurrentTime = [AppCurrentTime; [currentTime, currentTime+timeOfHyperpolarizingInput]];
    currentTime = currentTime + timeOfOneCycle;
end
AppCurrentVal = -Iapp*ones(size(AppCurrentTime,1),1);

%% Setting up the equations of the model .
numTCSpikes  = size(AppCurrentVal,1);
de =  'dV/dt=(@current'; %+ HyperP(t)';
for u = 1:numTCSpikes
    de = strcat(de,strcat('+ Iapp',num2str(u),'(t)'));
end
de = strcat(de,')/Cm');
temp = {de}; 
for v = 1:numTCSpikes % Depolarizing input at constant interval
    temp{v+1,1} = strcat('Iapp',num2str(v),'(t)=0*(t<AppCurrentTime(',num2str(v),',1))+AppCurrentVal(',...
        num2str(v),')*(t>=AppCurrentTime(',num2str(v),',1)&&t<=AppCurrentTime(',num2str(v),',2))+0*(t>AppCurrentTime(',num2str(v),',2))');
end 

eqns = [temp; {'Cm = 1'; % uF/cm^2
    'spike_threshold = -5'; 
    'V(0) = -60'}];

%% Setting populations and mechanisms in the model
mechanism_listS = {'iNa_TC_AS17',...
'iK_TC_AS17',...
'iLeak_TC_AS17',...
'iKLeak_TC_CV19',...
'CaBuffer_TC_AS17',...
'iH_TC_CV19',...
'iT_TC_AS17'};

specification = [];
specification.populations(1).name = 'Ed';
specification.populations(1).size = 1;
specification.populations(1).equations = eqns;
specification.populations(1).mechanism_list = mechanism_listS;
specification.populations(1).parameters = {'AppCurrentVal',AppCurrentVal,...
    'AppCurrentTime',AppCurrentTime, 'gT', gT_temp, 'Vshift', Vshift_temp}; 

%% Running simulations        
data = dsSimulate(specification,'tspan',[0 totalSimulationTime]);
rmdir('solve', 's');
        
end