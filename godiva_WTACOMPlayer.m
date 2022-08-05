function godiva_WTACOMPlayer(block)
% godiva_WTACOMPlayer (winner-take-all competitive layer) parameters:
%   1: block ID (string)
%   2: number of independent zones in input vector (nz)
%   3: noise level
%   4: display (1/0)
%    
% Fullmodel description:
%   Inputs:
%      1: Inhibition.   1- or N- dimensional vector
%      2: Input.        N-dimensional vector  
%      2: Gate.         1- or N- dimensional vector
%       note: N-dimensional vectors are treated internally as [N/nz,nz] matrices if
%       multiple zones exist
%   Internal states:
%      1: Plan cells    N-dimensional vector
%      2: Choice cells  N-dimensional vector
%   Behavior:
%      1: When the input vector is nonzero Plan-cells load and store the
%      normalized input (note: use transient inputs. The Plan-cells
%      activation is clamped at the input vector values during the time
%      when the input vector is nonzero)
%      2: When all of the Choice-cells activation is zero, the input from
%      Plan-cells (multiplied by the 'Gate' term) is stored in the
%      Choice-cells and a winner-takes-all procedure normalizes their
%      activation (maximum-valued cell is set to 1, the rest are set to 0),
%      followed by the back-inhibition of the original maximum-valued
%      Plan-cell activation. Computations are performed separately within each
%      'zone' of the layer (i.e. each 'zone' computes the maximum among the
%      cells within the same 'zone')
%      3: When the 'Inhibition' input is nonzero, the correspoinding
%      choice-cells activation is inhibited (set and maintained to zero
%      until the inhibition stops). 
%

% Level-2 M file S-Function.
  setup(block);  
end

%% Initialization   
function setup(block)

  % Register number of dialog parameters   
  block.NumDialogPrms = 4;
  block.DialogPrmsTunable = {'Nontunable','Nontunable','Nontunable','Nontunable'};

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
  block.NumDworks = 4;
  block.Dwork(1).Name = 'PlanLayer'; 
  block.Dwork(1).Dimensions      = ndims;
  block.Dwork(1).DatatypeID      = 0;
  block.Dwork(1).Complexity      = 'Real';
  block.Dwork(1).UsedAsDiscState = true;
  block.Dwork(2).Name = 'ChoiceLayer'; 
  block.Dwork(2).Dimensions      = ndims;
  block.Dwork(2).DatatypeID      = 0;
  block.Dwork(2).Complexity      = 'Real';
  block.Dwork(2).UsedAsDiscState = true;
  block.Dwork(3).Name = 'LayerColumns'; 
  block.Dwork(3).Dimensions      = ndims;
  block.Dwork(3).DatatypeID      = 0;
  block.Dwork(3).Complexity      = 'Real';
  block.Dwork(3).UsedAsDiscState = false;
  block.Dwork(4).Name = 'counter'; 
  block.Dwork(4).Dimensions      = 1;
  block.Dwork(4).DatatypeID      = 0;
  block.Dwork(4).Complexity      = 'Real';
  block.Dwork(4).UsedAsDiscState = false;
end

function SetInputDims(block, port, dm)
    block.InputPort(port).Dimensions = dm;
    if port==2, block.OutputPort(1).Dimensions = dm; end
end

function InitConditions(block)
  global GODIVA_x;
  
  ndims = block.InputPort(2).CurrentDimensions;
  block.Dwork(1).Data= zeros(ndims,1);
  block.Dwork(2).Data = zeros(ndims,1);
  if numel(block.DialogPrm(2).Data)==1, block.Dwork(3).Data=reshape(repmat(1:block.DialogPrm(2).Data,[ndims/block.DialogPrm(2).Data,1]),[],1);
  elseif numel(block.DialogPrm(2).Data)==ndims, block.Dwork(3).Data=block.DialogPrm(2).Data;
  else error('incorrect dimensions of Dialog Parameter #2'); end
  block.Dwork(4).Data = 0;

  %display initializations
  GODIVA_x.States.(block.DialogPrm(1).Data).PlanCells=block.Dwork(1).Data;
  GODIVA_x.States.(block.DialogPrm(1).Data).ChoiceCells=block.Dwork(2).Data;
  GODIVA_x.States.(block.DialogPrm(1).Data).Columns=block.Dwork(3).Data;
  for n1=1:block.NumInputPorts,
        GODIVA_x.States.(block.DialogPrm(1).Data).InputProjections(n1).Data=[];
  end
  delete(findobj(0,'tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Plan']));
  delete(findobj(0,'tag',[mfilename,'_disp_',block.DialogPrm(1).Data,'_Choice']));
end


%% Output & Update equations   
function Output(block)
  % system output
  block.OutputPort(1).Data = block.Dwork(2).Data;

end

function Update(block)
  global GODIVA_x;

  % store states for display
  GODIVA_x.States.(block.DialogPrm(1).Data).PlanCells=cat(2,GODIVA_x.States.(block.DialogPrm(1).Data).PlanCells,block.Dwork(1).Data);
  GODIVA_x.States.(block.DialogPrm(1).Data).ChoiceCells=cat(2,GODIVA_x.States.(block.DialogPrm(1).Data).ChoiceCells,block.Dwork(2).Data);
  for n1=1:block.NumInputPorts,
        GODIVA_x.States.(block.DialogPrm(1).Data).InputProjections(n1).Data=cat(2,GODIVA_x.States.(block.DialogPrm(1).Data).InputProjections(n1).Data,block.InputPort(n1).Data);
  end
  

  % start block computations
  Inp=max(0,block.InputPort(2).Data);
  Gate=block.InputPort(3).Data;
  Inhibition=block.InputPort(1).Data;
  M1=block.Dwork(1).Data;
  M2=block.Dwork(2).Data;
  columns=block.Dwork(3).Data;
  dodisp=block.DialogPrm(4).Data;

  % Choice Layer excitation
  if any(Gate)&&~any(M2), 
      t=M1.*Gate;
      tmax=accumarray(columns,t,[],@max);
      M2=double((tmax(columns)==t)&(t>0));
  end
  % Choice Layer inhibition
  if any(Inhibition),
      t=M2.*Inhibition;
      M2(t>0)=0;
  end
  % Plan Layer excitation
  if any(Inp), 
      t=Inp;
      if block.DialogPrm(3).Data, t=max(0,t+block.DialogPrm(3).Data*randn(size(Inp))); end
      tsum=accumarray(columns,t);
      M1 = t./max(eps,tsum(columns));
  end
  % Plan Layer inhibition
  M1(M2>0)=0;
  t=M1;
  tsum=accumarray(columns,t);
  M1 = t./max(eps,tsum(columns));
  % end block computations
  
  ischanged=any(abs(block.Dwork(1).Data-M1)>eps)|any(abs(block.Dwork(2).Data-M2)>eps);
  block.Dwork(1).Data = M1;
  block.Dwork(2).Data = M2;
  block.Dwork(4).Data = block.Dwork(4).Data+1;
  
  
  % status display
  if dodisp&&~rem(block.Dwork(4).Data,dodisp)&&ischanged
      godiva_displaystatus(block);
  end
  % stops simulation
  if isequal(get_param(gcs,'StopTime'),'inf')
      allzero=~any(block.Dwork(1).Data>0)&~any(block.Dwork(2).Data>0);
      if allzero,
          GODIVA_x.run=GODIVA_x.run-1;
          if GODIVA_x.run<0, set_param(gcs,'SimulationCommand','stop'); end
      else
          GODIVA_x.run=2*numel(fieldnames(GODIVA_x.States)); 
      end
  end

end

