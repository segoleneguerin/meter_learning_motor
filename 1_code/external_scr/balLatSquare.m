function M = balLatSquare(N)

% returns design matrix contrabalanced for N conditions using latin square. 

V = 1:N ;        % values in each column
CSI = [V ; -V] ; % circular shift index
M = zeros(N) ;   % pre-allocation

% the first colum just contains the numbers 1 to N
M(:,1) = V(:) ;
for i=2:N
    % every column contains the numbers 1 to N shifted circularly according
    % to CSI
    M(:,i) =  rem(V(:)+CSI(i-1)+(N-1),N) + 1 ;
end


% randomize the values 1:N
rN = randperm(N) ;
R = rN(M) ;


if mod(N,2)
    M = [M;M];
    M(N+1:end,:) = fliplr(M(N+1:end,:));
end


end
