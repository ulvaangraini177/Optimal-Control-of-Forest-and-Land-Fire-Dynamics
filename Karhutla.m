
clear; clc; close all;
format short g;

%% ============================================================
%  OPTIMAL CONTROL OF FOREST FIRES
%  FOUR-COMPARTMENT MODEL USING FORWARD-BACKWARD SWEEP METHOD
%
%  Compartments:
%    V : Healthy natural forest area (ha)
%    A : Agricultural/plantation land (ha)
%    F : Active burning area (ha)
%    R : Degraded land after fire (ha)
%
%  Controls:
%    u1 : Fire suppression
%    u2 : Land rehabilitation / rewetting
%    u3 : Prevention of forest conversion
%
%  Scenarios:
%    Case I   : No control
%    Case II  : u1 only
%    Case III : u2 only
%    Case IV  : u3 only
%    Case V   : All controls
%% ============================================================


%% 1. MODEL PARAMETERS

p.alpha  = 2e-4;
p.beta1  = 1.5e-5;
p.beta2  = 2e-5;
p.gamma  = 0.06;
p.kappa1 = 0.10;
p.omega  = 3e-4;
p.kappa2 = 1e-3;
p.mu     = 2e-4;

% Objective-function weights
p.WA = 0.5;
p.WF = 8;
p.WR = 1.5;

% Control-cost coefficients
p.C1 = 8;
p.C2 = 4;
p.C3 = 5;


%% 2. SIMULATION SETTINGS

t0 = 0;
tf = 100;
N  = 501;

t  = linspace(t0,tf,N);
dt = t(2)-t(1);

% Initial conditions: [V0; A0; F0; R0]
X0 = [500; 300; 50; 150];

% Total area
K = sum(X0);

% FBSM settings
max_iter = 1000;
tol      = 1e-7;
relax    = 0.5;


%% 3. SCENARIO DEFINITIONS

scenario_keys = {
    'no_control'
    'u1_only'
    'u2_only'
    'u3_only'
    'all_controls'
};

scenario_names = {
    'Case I: No control'
    'Case II: u1 only'
    'Case III: u2 only'
    'Case IV: u3 only'
    'Case V: All controls'
};

% Columns correspond to u1, u2, and u3
active_controls = [
    0 0 0
    1 0 0
    0 1 0
    0 0 1
    1 1 1
];

n_scenarios = numel(scenario_keys);

% Colors for the controlled trajectories in the individual figures
case_colors = {
    [0 0 1]       % Case II: blue
    [0 0.6 0]     % Case III: green
    [0.7 0 0.7]   % Case IV: magenta
    [0 0 0]       % Case V: black
};

% Line styles for comparisons across all five scenarios
% IMPORTANT: Define this before using line_styles in any plot.
line_styles = {
    'r--'         % Case I: No control
    'b-'          % Case II: u1 only
    'g-'          % Case III: u2 only
    'm-'          % Case IV: u3 only
    'k-'          % Case V: All controls
};

compartment_names = {
    'Healthy Forest Area V(t)'
    'Agricultural/Plantation Land A(t)'
    'Active Burning Area F(t)'
    'Degraded Land R(t)'
};

compartment_labels = {
    'V(t) (ha)'
    'A(t) (ha)'
    'F(t) (ha)'
    'R(t) (ha)'
};


%% 4. RUN ALL SCENARIOS USING FBSM

scenarios = struct();

fprintf('\n====================================================\n');
fprintf(' FORWARD-BACKWARD SWEEP METHOD\n');
fprintf('====================================================\n');

for s = 1:n_scenarios

    fprintf('\nRunning %s ...\n',scenario_names{s});

    active_mask = logical(active_controls(s,:));

    result = fbsm_solver( ...
        t, X0, p, active_mask, max_iter, tol, relax);

    result.t = t;

    scenarios.(scenario_keys{s}) = result;

    fprintf('Iterations : %d\n',result.iterations);
    fprintf('Converged  : %d\n',result.converged);
    fprintf('Final V    : %.6f ha\n',result.X(1,end));
    fprintf('Final A    : %.6f ha\n',result.X(2,end));
    fprintf('Final F    : %.6f ha\n',result.X(3,end));
    fprintf('Final R    : %.6f ha\n',result.X(4,end));

end


%% 5. INDIVIDUAL COMPARTMENT DYNAMICS FOR EACH SCENARIO
% Each scenario has one figure containing four subplots.
% Red dashed line : No-control baseline
% Solid line      : The scenario being investigated

no_control = scenarios.no_control;

for s = 1:n_scenarios

    result = scenarios.(scenario_keys{s});

    figure( ...
        'Color','w', ...
        'Name',scenario_names{s}, ...
        'NumberTitle','off');

    for j = 1:4

        subplot(2,2,j);
        hold on;

        % Baseline trajectory
        plot( ...
            no_control.t, ...
            no_control.X(j,:), ...
            'r--', ...
            'LineWidth',2);

        % Controlled trajectory
        if s > 1

            plot( ...
                result.t, ...
                result.X(j,:), ...
                '-', ...
                'Color',case_colors{s-1}, ...
                'LineWidth',2);

            legend( ...
                {'No control',scenario_names{s}}, ...
                'Location','best');

        else

            legend( ...
                {'No control'}, ...
                'Location','best');

        end

        xlabel('Time (days)');
        ylabel('Area (ha)');
        title(compartment_names{j});

        xlim([t0 tf]);
        xticks(0:10:tf);

        grid on;
        box on;
        hold off;

    end

    sgtitle(scenario_names{s});

end


%% 6. CONTROL PROFILES FOR EACH SCENARIO
% Each figure contains u1, u2, and u3.

for s = 1:n_scenarios

    result = scenarios.(scenario_keys{s});

    figure( ...
        'Color','w', ...
        'Name',['Control Profiles - ',scenario_names{s}], ...
        'NumberTitle','off');

    control_names = {
        'Control u_1: Fire Suppression'
        'Control u_2: Rehabilitation / Rewetting'
        'Control u_3: Forest Conversion Prevention'
    };

    for k = 1:3

        subplot(3,1,k);
        plot(result.t,result.U(k,:),'LineWidth',2);

        xlabel('Time (days)');
        ylabel(['u_',num2str(k),'(t)']);
        title(control_names{k});

        xlim([t0 tf]);
        ylim([0 1]);
        xticks(0:10:tf);

        grid on;
        box on;

    end

    sgtitle(['Optimal Control Profiles: ',scenario_names{s}]);

end


%% 6B. COMBINED CONTROL PROFILES: u1, u2, AND u3
% Case V: All controls

result = scenarios.all_controls;

figure( ...
    'Color','w', ...
    'Name','Combined Optimal Control Profiles', ...
    'NumberTitle','off');

hold on;

plot(result.t, result.U(1,:), 'b-', ...
    'LineWidth', 2);

plot(result.t, result.U(2,:), 'g-', ...
    'LineWidth', 2);

plot(result.t, result.U(3,:), 'm-', ...
    'LineWidth', 2);

xlabel('Time (days)');
ylabel('Control Intensity');
title('Combined Optimal Control Profiles (Case V)');

xlim([t0 tf]);
ylim([0 1]);
xticks(0:10:tf);

legend({'u_1: Fire Suppression', ...
    'u_2: Rehabilitation / Rewetting', ...
    'u_3: Forest Conversion Prevention'}, ...
    'Location','best');

grid on;
box on;
hold off;


%% 7. QUANTITATIVE COMPARISON OF ALL SCENARIOS
%
% Objective functional:
%
% J = integral [
%       WA*A + WF*F + WR*R
%       + C1/2*u1^2 + C2/2*u2^2 + C3/2*u3^2
%     ] dt
%
% Lower J indicates a lower value of the specified objective.

case_label = strings(n_scenarios,1);

Integral_A = zeros(n_scenarios,1);
Integral_F = zeros(n_scenarios,1);
Integral_R = zeros(n_scenarios,1);

Final_V = zeros(n_scenarios,1);
Final_A = zeros(n_scenarios,1);
Final_F = zeros(n_scenarios,1);
Final_R = zeros(n_scenarios,1);

Control_Effort = zeros(n_scenarios,1);
Objective_J = zeros(n_scenarios,1);
Fire_Reduction_Percent = zeros(n_scenarios,1);

baseline_fire_burden = trapz( ...
    no_control.t, no_control.X(3,:));

for s = 1:n_scenarios

    result = scenarios.(scenario_keys{s});

    case_label(s) = string(scenario_names{s});

    % Integrated compartment trajectories
    Integral_A(s) = trapz(result.t,result.X(2,:));
    Integral_F(s) = trapz(result.t,result.X(3,:));
    Integral_R(s) = trapz(result.t,result.X(4,:));

    % Final compartment values
    Final_V(s) = result.X(1,end);
    Final_A(s) = result.X(2,end);
    Final_F(s) = result.X(3,end);
    Final_R(s) = result.X(4,end);

    % Total control effort
    control_integrand = ...
        (p.C1/2)*(result.U(1,:).^2) + ...
        (p.C2/2)*(result.U(2,:).^2) + ...
        (p.C3/2)*(result.U(3,:).^2);

    Control_Effort(s) = trapz(result.t,control_integrand);

    % Objective functional
    objective_integrand = ...
        p.WA*result.X(2,:) + ...
        p.WF*result.X(3,:) + ...
        p.WR*result.X(4,:) + ...
        control_integrand;

    Objective_J(s) = trapz(result.t,objective_integrand);

    % Fire-burden reduction relative to no control
    Fire_Reduction_Percent(s) = ...
        100*(baseline_fire_burden-Integral_F(s)) ...
        / max(abs(baseline_fire_burden),eps);

end

ResultsTable = table( ...
    case_label, ...
    Integral_A, ...
    Integral_F, ...
    Integral_R, ...
    Final_V, ...
    Final_A, ...
    Final_F, ...
    Final_R, ...
    Control_Effort, ...
    Objective_J, ...
    Fire_Reduction_Percent, ...
    'VariableNames',{ ...
        'Scenario', ...
        'Integral_A', ...
        'Integral_F', ...
        'Integral_R', ...
        'Final_V', ...
        'Final_A', ...
        'Final_F', ...
        'Final_R', ...
        'Control_Effort', ...
        'Objective_J', ...
        'Fire_Reduction_Percent'});

fprintf('\n====================================================\n');
fprintf(' QUANTITATIVE COMPARISON OF ALL SCENARIOS\n');
fprintf('====================================================\n');

disp(ResultsTable);


%% 8. COMPARISON OF ACTIVE BURNING AREA F(t), CASES I-V
% Five curves in one figure.

figure( ...
    'Color','w', ...
    'Name','Comparison of Active Burning Area', ...
    'NumberTitle','off');

hold on;

for s = 1:n_scenarios

    result = scenarios.(scenario_keys{s});

    plot( ...
        result.t, ...
        result.X(3,:), ...
        line_styles{s}, ...
        'LineWidth',2);

end

xlabel('Time (days)');
ylabel('Active Burning Area F(t) (ha)');
title('Comparison of Active Burning Area Across Cases');

xlim([t0 tf]);
xticks(0:10:tf);

legend(scenario_names,'Location','best');

grid on;
box on;
hold off;


%% 9. COMPARISON OF DEGRADED LAND R(t), CASES I-V
% Five curves in one figure.

figure( ...
    'Color','w', ...
    'Name','Comparison of Degraded Land', ...
    'NumberTitle','off');

hold on;

for s = 1:n_scenarios

    result = scenarios.(scenario_keys{s});

    plot( ...
        result.t, ...
        result.X(4,:), ...
        line_styles{s}, ...
        'LineWidth',2);

end

xlabel('Time (days)');
ylabel('Degraded Land R(t) (ha)');
title('Comparison of Degraded Land Across Cases');

xlim([t0 tf]);
xticks(0:10:tf);

legend(scenario_names,'Location','best');

grid on;
box on;
hold off;


%% 10. FOUR ADDITIONAL COMBINED COMPARTMENT GRAPHS
% One figure for each compartment.
% Each figure compares all five scenarios.
%
% Case I   : Red dashed
% Case II  : Blue solid
% Case III : Green solid
% Case IV  : Magenta solid
% Case V   : Black solid

for j = 1:4

    figure( ...
        'Color','w', ...
        'Name',['Combined Cases - ',compartment_names{j}], ...
        'NumberTitle','off');

    hold on;

    for s = 1:n_scenarios

        result = scenarios.(scenario_keys{s});

        plot( ...
            result.t, ...
            result.X(j,:), ...
            line_styles{s}, ...
            'LineWidth',2);

    end

    xlabel('Time (days)');
    ylabel(compartment_labels{j});
    title([compartment_names{j},' Across Cases']);

    xlim([t0 tf]);
    xticks(0:10:tf);

    legend(scenario_names,'Location','best');

    grid on;
    box on;
    hold off;

end


%% 11. FINAL STATE AND AREA-CONSERVATION CHECK

fprintf('\n====================================================\n');
fprintf(' FINAL STATE AND AREA CONSERVATION\n');
fprintf('====================================================\n');

fprintf('Initial total area = %.10f ha\n',K);

for s = 1:n_scenarios

    result = scenarios.(scenario_keys{s});

    final_total = sum(result.X(:,end));
    conservation_error = abs(final_total-K);

    fprintf('\n%s\n',scenario_names{s});
    fprintf('  Final V = %.8f ha\n',result.X(1,end));
    fprintf('  Final A = %.8f ha\n',result.X(2,end));
    fprintf('  Final F = %.8f ha\n',result.X(3,end));
    fprintf('  Final R = %.8f ha\n',result.X(4,end));
    fprintf('  Total area = %.10f ha\n',final_total);
    fprintf('  Conservation error = %.4e ha\n',conservation_error);

end

fprintf('\nSimulation completed.\n');


%% ============================================================
%  LOCAL FUNCTIONS
%  Keep these functions at the end of the script.
%% ============================================================


function result = fbsm_solver( ...
    t,X0,p,active_mask,max_iter,tol,relax)

    N  = numel(t);
    dt = t(2)-t(1);

    % Initial control guess
    U = zeros(3,N);

    % Enforce the active-control configuration
    U(~active_mask,:) = 0;

    converged = false;
    error_control = Inf;

    for iter = 1:max_iter

        % Forward sweep: state equations
        X = forward_states(t,X0,U,p);

        % Backward sweep: costate equations
        Lam = backward_costates(t,X,U,p);

        % Update the controls from the optimality conditions
        U_new = zeros(3,N);

        U_new(1,:) = ...
            p.kappa1 .* X(3,:) .* ...
            (Lam(3,:)-Lam(4,:)) ./ p.C1;

        U_new(2,:) = ...
            p.kappa2 .* X(4,:) .* ...
            (Lam(4,:)-Lam(1,:)) ./ p.C2;

        U_new(3,:) = ...
            p.alpha .* X(1,:) .* ...
            (Lam(2,:)-Lam(1,:)) ./ p.C3;

        % Control constraints: 0 <= u_i <= 1
        U_new = min(max(U_new,0),1);

        % Disable controls that are not active in the scenario
        U_new(~active_mask,:) = 0;

        % Relaxation to improve FBSM convergence
        U_relaxed = relax*U_new + (1-relax)*U;

        % Reapply constraints after relaxation
        U_relaxed = min(max(U_relaxed,0),1);
        U_relaxed(~active_mask,:) = 0;

        % Maximum absolute control difference
        error_control = max(abs(U_relaxed(:)-U(:)));

        U = U_relaxed;

        if error_control < tol
            converged = true;
            break;
        end

    end

    % Recompute states and costates using the final control
    X   = forward_states(t,X0,U,p);
    Lam = backward_costates(t,X,U,p);

    result.t = t;
    result.X = X;
    result.U = U;
    result.Lam = Lam;
    result.iterations = iter;
    result.converged = converged;
    result.error_control = error_control;

end


function X = forward_states(t,X0,U,p)

    N  = numel(t);
    dt = t(2)-t(1);

    X = zeros(4,N);
    X(:,1) = X0;

    % Forward integration using classical fourth-order Runge-Kutta
    for i = 1:N-1

        x_i = X(:,i);
        u_i = U(:,i);

        u_mid = 0.5*(U(:,i)+U(:,i+1));

        k1 = state_rhs(x_i,u_i,p);

        k2 = state_rhs( ...
            x_i + 0.5*dt*k1, u_mid, p);

        k3 = state_rhs( ...
            x_i + 0.5*dt*k2, u_mid, p);

        k4 = state_rhs( ...
            x_i + dt*k3, U(:,i+1), p);

        X(:,i+1) = x_i + ...
            (dt/6)*(k1+2*k2+2*k3+k4);

    end

end


function Lam = backward_costates(t,X,U,p)

    N  = numel(t);
    dt = t(2)-t(1);

    Lam = zeros(4,N);

    % Terminal conditions for a fixed final time
    Lam(:,N) = zeros(4,1);

    % Backward integration using fourth-order Runge-Kutta
    for i = N-1:-1:1

        x_next = X(:,i+1);
        u_next = U(:,i+1);
        lam_next = Lam(:,i+1);

        x_mid = 0.5*(X(:,i)+X(:,i+1));
        u_mid = 0.5*(U(:,i)+U(:,i+1));

        % Integrate d(lambda)/d(t) = costate_rhs backward
        k1 = costate_rhs(x_next,u_next,lam_next,p);

        k2 = costate_rhs( ...
            x_mid,u_mid,lam_next-0.5*dt*k1,p);

        k3 = costate_rhs( ...
            x_mid,u_mid,lam_next-0.5*dt*k2,p);

        k4 = costate_rhs( ...
            X(:,i),U(:,i),lam_next-dt*k3,p);

        Lam(:,i) = lam_next - ...
            (dt/6)*(k1+2*k2+2*k3+k4);

    end

end


function dX = state_rhs(X,U,p)

    V = X(1);
    A = X(2);
    F = X(3);
    R = X(4);

    u1 = U(1);
    u2 = U(2);
    u3 = U(3);

    dV = -p.alpha*(1-u3)*V ...
         -p.beta1*V*F ...
         +(p.omega+p.kappa2*u2)*R;

    dA = p.alpha*(1-u3)*V ...
         -p.beta2*A*F ...
         -p.mu*A;

    dF = p.beta1*V*F ...
         +p.beta2*A*F ...
         -(p.gamma+p.kappa1*u1)*F;

    dR = (p.gamma+p.kappa1*u1)*F ...
         +p.mu*A ...
         -(p.omega+p.kappa2*u2)*R;

    dX = [dV; dA; dF; dR];

end


function dLam = costate_rhs(X,U,Lam,p)

    V = X(1);
    A = X(2);
    F = X(3);
    R = X(4);

    u1 = U(1);
    u2 = U(2);
    u3 = U(3);

    lam1 = Lam(1);
    lam2 = Lam(2);
    lam3 = Lam(3);
    lam4 = Lam(4);

    % Costate equation:
    % d(lambda_i)/dt = -dH/dx_i

    dlam1 = ...
        lam1*(p.alpha*(1-u3)+p.beta1*F) ...
        -lam2*p.alpha*(1-u3) ...
        -lam3*p.beta1*F;

    dlam2 = ...
        -p.WA ...
        +lam2*(p.beta2*F+p.mu) ...
        -lam3*p.beta2*F ...
        -lam4*p.mu;

    dlam3 = ...
        -p.WF ...
        +lam1*p.beta1*V ...
        +lam2*p.beta2*A ...
        -lam3*(p.beta1*V+p.beta2*A ...
               -p.gamma-p.kappa1*u1) ...
        -lam4*(p.gamma+p.kappa1*u1);

    dlam4 = ...
        -p.WR ...
        -lam1*(p.omega+p.kappa2*u2) ...
        +lam4*(p.omega+p.kappa2*u2);

    dLam = [dlam1; dlam2; dlam3; dlam4];

end
