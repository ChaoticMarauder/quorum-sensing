function f=firstOrderODEf(t,u)
%firstOrderODEf - Residue function for first-order ODE system
%Computes residue of discretized PDE with first-order time derivative.
%This undocumented function may be removed in a future release.
%
%       Copyright 2015-2016 The MathWorks, Inc.

global femodel
%{ @@@ Custom @@@ %%
  global enableSinglecellEq;
  global bactNodes;
  global bactRingDensity;
  global bactNodeCoeffs;
  nBact= length(bactNodes);
%} @@@ Custom @@@ %%

f= zeros(size(u));
for i= 1:size(u,2)

  if ~(femodel.vq || femodel.vg || femodel.vh || femodel.vr || ...
          femodel.vc || femodel.va || femodel.vf)
      if size(u,2)>1, error('This codepath can''t be used with vectorized=''on'''); end
      if enableSinglecellEq
        f=[-femodel.K*u(1:end-nBact*8)+femodel.F; zeros(nBact*8,1)];
      else, f=-femodel.K*u+femodel.F;
      end
      return;
  end

  % make uFull
  if(femodel.numConstrainedEqns == femodel.totalNumEqns)
      if enableSinglecellEq, uFull= u(1:end-nBact*8,i);
      else, uFull= u(:,i); end
  else
      if enableSinglecellEq, uFull= femodel.B*u(1:end-nBact*8,i) + femodel.ud;
      else, uFull= femodel.B*u(:,i) + femodel.ud; end
  end

  if femodel.vq || femodel.vg || femodel.vh || femodel.vr
    if i==1
      [femodel.Q,femodel.G,femodel.H,femodel.R]=femodel.thePde.assembleBoundary(uFull,t);
    end
  end

  % [K,F,A]= formGlobalKF2D(uFull)
  if femodel.vc || femodel.va || femodel.vf
    error('[firstOrderODEf]: this code has been stripped!');
  end

  if ~(femodel.vh || femodel.vr)
      % neither H nor R are functions of t or u
      K = femodel.K + femodel.A + femodel.Q;
      F = femodel.B'*(femodel.F + femodel.G - K*femodel.ud);
      K = femodel.B'*K*femodel.B;
  else
      dt=femodel.tspan*sqrt(eps);
      t1=t+dt;
      dt=t1-t;
      % Doesn't enter
      if femodel.vd
          if(femodel.nrp==2)
              femodel.Mass = formGlobalM2D(femodel.emptyPDEModel, femodel.p, femodel.t, femodel.coefstruct,uFull,t,'d');
          elseif(femodel.nrp==3)
              femodel.Mass = formGlobalM3D(femodel.emptyPDEModel, femodel.p, femodel.t, femodel.coefstruct,uFull,t,'d');
          end
      end
      if femodel.vh
        error('[firstOrderODEf]: this code has been stripped!');
      else
        HH=femodel.H*femodel.Or;
        ud=femodel.Or*(HH\femodel.R);
        [~,~,~,R]=femodel.thePde.assembleBoundary(uFull,t1);
        ud1=femodel.Or*(HH\R);
        K=femodel.Nu'*(femodel.K+femodel.A+femodel.Q)*femodel.Nu;
        F=femodel.Nu'*((femodel.F+femodel.G)-(femodel.K+femodel.A+femodel.Q)*ud - ...
            femodel.Mass*(ud1-ud)/dt);
      end
      femodel.ud=ud;
  end

  %% @@@ Custom @@@ %%
  returnOn= false;
  if ~enableSinglecellEq
    f(:,i)= -K*u(:,i)+F;
    returnOn= true;
  end
  if ~returnOn
    % Initial calculation for d(n_i)/dt
    f(:,i)= [-K*u(1:end-nBact*8,i)+F; zeros(nBact*8,1)];

    for b= 1:nBact
      nBactRing= bactRingDensity(b);
      ahl= sum(u(bactNodes{b},i).*bactNodeCoeffs{b});
      yIdx= (nBact-b+1)*8-1;    % where the y variables for this bacterium start (relative to end)
      % y variables for this bacterium
      yBact= [u(end-yIdx: end-yIdx+4,i); ahl; u(end-yIdx+5: end-yIdx+7,i); 0;nBactRing];

      dy= singlecell.model_weber(1,yBact,false,false);
      %dy= singlecell.model(1,yBact(1:9));
      ahlProd= dy(6).*bactNodeCoeffs{b};

      % dy(6) contains the total derivative of all the contributing terms
      % dy(6):= d(ahl)/dt
      % From the definition of <ahl>, an equation that must hold can be derived with
      % the chain rule: mean(n_i')==AHL'
      % A correction factor will be added to the n_i' to accomodate it:
      % corr_ahl= AHL' - mean(n_i')
      %f(bactNodes{b}(1:2))= f(bactNodes{b}(1:2)) - mean(f(bactNodes{b}(1:2))) + dy(6);

      % Note:
      %   The cylindrical symmetry allows for many bacteria that sit on a cylindrical ring
      % of set radius to be simulated by a single set of singlecell equations. Their total
      % effect is incorporated by multiplying their number with their output (dy_6)
      f(bactNodes{b},i)= f(bactNodes{b},i) + ahlProd;

      f(end-yIdx: end-yIdx+7,i)= dy([1:5,7:9]);
    end

    %log10([max(u(1:end-16)) dy(6)])

    % Don't allow nodes to stay negative
    %f(u<=0 & f<=0)= -f(u<=0 & f<=0);%-u(u<=0 & f<=0);
  end
  
end
end
