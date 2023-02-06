function godiva_WTACOMPlayer(block)
% godiva_WTACOMPlayer (winner-take-all competitive layer) parameters:
%   1: block ID (string)
%   2: noise level
%   3: display (1/0)
%    
% Fullmodel description:
%   Inputs:
%      1: Inhibition.   1- or N- dimensional vector
%      2: Input.        N-dimensional vector  
%   Internal states:
%      1: Choice cells  N-dimensional vector
%   Behavior:
%      1: When the input vector is nonzero Choice-cells load and store the
%      input (note: use transient inputs. The Plan-cells
%      activation is clamped at the input vector values during the time
%      when the input vector is nonzero)
%      2: When the 'Inhibition' input is nonzero, the correspoinding
%      choice-cells activation is inhibited (set and maintained to zero
%      until the inhibition stops). 
%

% Level-2 M file S-Function.
  setup(block);  
end

%% Initialization   
function setup(block)

  % Register number of dialog parameters   
  block.NumDialogPrms = 3;
  block.DialogPrmsTunable = {'Nontunable','Nontunable','Nontunable'};

  % Register number of input and output ports
  block.NumInputPorts  = 3;
  block.NumOutputPorts = 1;

  % Setup functional port properties to dynamically inherited.
  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;
 
  block.InputPort(1).Dimensions        = -1;
  block.InputPort(1).DirectFeedthrough = false;
  block.InputPort(2).Dimensions        = -1;
  block.InputPort(2).DirectFeedthrough = false;
  block.InputPort(3).Dimensions        = -1;
  block.InputPort(3).DirectFeedthrough = false;
  block.OutputPort(1).Dimensions       = -1;
  
  % Set block sample time to discrete
  block.SampleTimes = [-1 0];
  
  % Register methods
  block.RegBlockMethod('SetInputPortDimensions',  @SetInputDims);
  block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
  block.RegBlockMethod('InitializeConditions',    @InitConditions);  
  block.RegBlockMethod('Outputs',                 @Output);  
  block.RegBlockMethod('Update',                  @Update);  
  
end

function DoPostPropSetup(block)
  % Setup Dwork
  ndims = block.InputPort(2).CurrentDimensions;
  block.NumDworks = 2;
  block.Dwork(1).Name = 'PlanLayer'; 
  block.Dwork(1).Dimensions      = ndims;
  block.Dwork(1).DatatypeID      = 0;
  block.Dwork(1).Complexity      = 'Real';
  block.Dwork(1).UsedAsDiscState = true;
  block.Dwork(2).Name = 'counter'; 
  block.Dwork(2).Dimensions      = 1;
  block.Dwork(2).DatatypeID      = 0;
  block.Dwork(2).Complexity      = 'Real';
  block.Dwork(2).UsedAsDiscState = false;
end

function SetInputDims(block, port, dm)
    block.InputPort(port).Dimensions = dm;
    if port==2, block.OutputPort(1).Dimensions = dm; end
end

function InitConditions(block)
  global GODIVA_x;
  
  ndims = block.InputPort(2).CurrentDimensions;
  block.Dwork(1).Data= zeros(ndims,1);
  block.Dwork(2).Data = 0;

  %display initializations
  GODIVA_x.States.(block.DialogPrm(1).Data).ChoiceCells=block.Dwork(1).Data;
  GODIVA_x.States.(block.DialogPrm(1).Data).PlanCells=[];
  GODIVA_x.States.(block.DialogPrm(1).Data).Columns=ones(numel(block.Dwork(1).Data),1);
  for n1=1:block.NumInputPorts,
        GODIVA_x.States.(block.DialogPrm(1).Data).InputProjections(n1).Data=[];
  end
  delete(findobj(0,'tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Choice']));
end


%% Output & Update equations   
function Output(block)
  % system output
  block.OutputPort(1).Data = block.Dwork(1).Data;

end

function Update(block)
  global GODIVA_x;

  % store states for display
  GODIVA_x.States.(block.DialogPrm(1).Data).ChoiceCells=cat(2,GODIVA_x.States.(block.DialogPrm(1).Data).ChoiceCells,block.Dwork(1).Data);
  for n1=1:block.NumInputPorts,
        GODIVA_x.States.(block.DialogPrm(1).Data).InputProjections(n1).Data=cat(2,GODIVA_x.States.(block.DialogPrm(1).Data).InputProjections(n1).Data,block.InputPort(n1).Data);
  end
  

  % start block computations
  Inp=max(0,block.InputPort(2).Data);
  Inhibition=block.InputPort(1).Data;
  if numel(Inhibition)==1&&1<numel(Inp), Inhibition=repmat(Inhibition,size(Inp)); end % if no inhibition input, assume no inhibition
  M1=block.Dwork(1).Data;
  donoise=block.DialogPrm(2).Data;
  dodisp=block.DialogPrm(3).Data;

  % Choice Layer excitation
  if any(Inp), 
      t=Inp;
      if donoise, t=max(0,t+donoise*randn(size(Inp))); end
      M1 = t;
  end
  % Choice Layer inhibition
  if any(Inhibition),
      t=M1.*Inhibition;
      M1(t>0)=0;
  end
  % end block computations
  
  ischanged=any(abs(block.Dwork(1).Data-M1)>eps);
  block.Dwork(1).Data = M1;
  block.Dwork(2).Data = block.Dwork(2).Data+1;
    
  % status display
  if dodisp&&~rem(block.Dwork(2).Data,dodisp)&&ischanged
      godiva_displaystatus(block);
  end
  % stops simulation
  if isequal(get_param(gcs,'StopTime'),'inf')
      allzero=~any(block.Dwork(1).Data>0);
      if allzero,
          GODIVA_x.run=GODIVA_x.run-1;
          if GODIVA_x.run<0, set_param(gcs,'SimulationCommand','stop'); end
      else
          GODIVA_x.run=2*numel(fieldnames(GODIVA_x.States)); 
      end
  end

end

