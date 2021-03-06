function dy= model_wMembrane(t,y,N0, growthOn)

[aRkR,aIkI,PR,PI,dmR,dmI,kAHL, ...
 k1,k2,k3,k4,k5,k6,kR,kI,      ...
 dI,dR,dS,dSS,dAHL,~,          ...
 cellDNA,growth,dilution,      ...
 diffusiveLoss,totMembPerm]= singlecell.modelCoeffs(y,N0);

% Growth model calcs
growth.dN= 0;
if growthOn
  growth.dN= growth.r*y(11)*growth.p1*growth.p2;
  growth.dN= growth.dN/60;  % time multiplier (hour->min)
end

%y(1)=DNA
%y(2)=mRNALuxR
%y(3)=mRNALuxI
%y(4)=LuxI
%y(5)=LuxR
%y(6)=AHLint
%y(7)=LuxRAHL
%y(8)=LuxRAHL2
%y(9)=DNALuxRAHL2
%y(10)=AHLext
%y(11)=bacteria count
dy(1)=  -k5*y(8)*y(1) +k6*y(9) +cellDNA*growth.dN;
dy(2)=  aRkR*y(1) -dmR*y(2) +kR*y(9);
dy(3)=  aIkI*y(1) -dmI*y(3) +kI*y(9);
dy(4)=  PI*y(3) -dI*y(4);
dy(5)=  PR*y(2) -k1*y(5)*y(6) +k2*y(7) -dR*y(5);
dy(6)=  kAHL*y(4) -k1*y(5)*y(6) +k2*y(7) -dAHL*y(6) -totMembPerm*(y(6)-y(10));
dy(7)=  k1*y(5)*y(6) -k2*y(7) -2*k3*y(7)^2 +2*k4*y(8) -dS*y(7);
dy(8)=  k3*y(7)^2 -k4*y(8) -dSS*y(8) -k5*y(8)*y(1) +k6*y(9);
dy(9)=  k5*y(8)*y(1) -k6*y(9);
dy(10)= dilution*totMembPerm*(y(6)-y(10)) -dAHL*y(10) -diffusiveLoss*y(10);
dy(11)= growth.dN;
end
