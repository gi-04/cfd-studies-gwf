clc,clear

% https://www.youtube.com/watch?v=iKAVRgIrUOU
% https://github.com/matthias-research/pages/blob/master/tenMinutePhysics/17-fluidSim.html



% Velocidade � um vetor V = [u,;]

% Malha staggered (relembrar a tradu��o devida em portugu�s depois):
% Componentes horizontais da velocidade s�o posicionadas nas fronteiras
% laterais, componentes verticais ficam nas fronteiras de cima e de baixo

% << Passos de uma simula��o CFD >>
% 1 - Modificar valores da gravidade
% 2 - Tornar o fluido incompress�vel
% 3 - Mover o campo de velocidade (advec��o)

% Atualizar velocidade
% Para todo i,j:
% v_{i,j} = v_{i,j} + delta_t * g

% Diverg�ncia e for�ar incompressibilidade
% d = u_{i+1,j} - u_{i,j} + v_{i,j+1} - v_{i,j}
% u_{i,j}   += d/4
% u_{i+1,j} -= d/4
% v_{i,j}   += d/4
% v_{i,j+1} -= d/4

% Condi��es de contorno (por exemplo, fronteira esquerda de uma c�lula)
% d = u_{i+1,j} - u_{i,j} + v_{i,j+1} - v_{i,j}
% u_{i+1,j} -= d/3
% v_{i,j}   += d/3
% v_{i,j+1} -= d/3

% Caso geral (cada c�lula tem um fator de escala S, onde S = 0 nas condi��es de
% contorno e S = 1 nas demais c�lulas)
% d = o*(u_{i+1,j} - u_{i,j} + v_{i,j+1} - v_{i,j})   (sobrerelaxa��o, com 1<o<2)
% S = S_{i+1,j} + S_{i-1,j} + S_{i,j+1} + S_{i,j-1}
% u_{i,j}   += d*S_{i-1,j}/S
% u_{i+1,j} -= d*S_{i+1,j}/S
% v_{i,j}   += d*S_{i,j-1}/S
% v_{i,j+1} -= d*S_{i,j+1}/S


% Solu��o: m�todo de gauss-seidel
% para um n�mero de itera��es, solucionar as velocidades em toda a malha


% Press�o:
% p_{i,j} += d/S*rho*h/delta_t
% onde h � o espa�amento da malha



% Dados do problema
v_inf = 10; % [m/s]
rho = 1; % [kg/m^3]
g = -9.8; % [m/s^2]
delta_t = 0.5; % [s]
o_relax = 1.9; % Fator de sobre-relaxa��o
iter = 10; % N�mero de itera��es

% Dados da malha (dom�nio em forma de um degrau)
px = 200; % Quantidade de pontos na dire��o x
py = 100; % Quantidade de pontos na dire��o y (ambos estes incluem as fronteiras)
Lx = 20; % Comprimento do dom�nio [m]
Ly = 10; % Altura do dom�nio [m]
Dx = 50; % Comprimento do degrau [porcentagem do comprimento do dom�nio]
Dy = 50; % Altura do degrau [porcentagem da altura do dom�nio]
hx = Lx/(px-1); % Espa�amento entre pontos na dire��o x
hy = Ly/(py-1); % Espa�amento entre pontos na dire��o y

% Inicializar malha
pxT = px + 2; % Considera-se as c�lulas contornando aquelas do fluido
pyT = py + 2;
u = zeros(pyT,pxT);
v = zeros(pyT,pxT);
P = zeros(pyT,pxT);
d = zeros(pyT,pxT);
S = ones(pyT,pxT);
[graph_X,graph_Y] = meshgrid(linspace(0,Lx,pxT),linspace(0,Ly,pyT));
% Definir o ponto onde fica a quina do degrau
Dpx = floor(pxT*Dx/100);
Dpy = floor(pyT*Dy/100);
% Atribuir condi��es de contorno na entrada
%u(Dpy:pyT-1,2) = repmat(v_inf,,1);
for j = Dpy:pyT-1
    u(j,2) = v_inf;
end

% Zerar os pesos S nas fronteiras
S(end,1:end) = zeros(1,length(S(end,1:end))); % Cima
S(1,1:end) = zeros(1,length(S(1,1:end))); % Baixo
S(2:end-1,1) = zeros(length(S(2:end-1,1)),1); % Esquerda
S(2:end-1,end) = zeros(length(S(2:end-1,end)),1); % Direita
S(2:Dpy-1,2:Dpx-1) = zeros(size(S(2:Dpy-1,2:Dpx-1))); % Abaixo do degrau

% Loop principal
for loop = 1:iter

    disp(['Itera��o ',num2str(loop)])

    % Guardar os valores antigos
    u_old = u;
    v_old = v;
%    p_old = p;



    % Atualizar valores das componentes verticais devido � a��o da gravidade
    % Antes do degrau
    for j = 2:Dpx-1
        for i = Dpy+1:pyT-2
            v(i,j) = v(i,j) + delta_t*g;
        end
    end
    % Depois do degrau
    for j = Dpx:pxT-1
        for i = 2:pyT-2
            v(i,j) = v(i,j) + delta_t*g;
        end
    end

    % Atualizar valores de todas as componentes
    % Antes do degrau
    for j = 2:Dpx
        for i = Dpy:pyT-1
            d(i,j) = o_relax*(u(i+1,j) - u(i,j) + v(i,j+1) - v(i,j));
            Sp = S(i+1,j) + S(i-1,j) + S(i,j+1) + S(i,j-1);

            u(i,j) = u(i,j) + d(i,j)*S(i-1,j)/Sp;
            u(i+1,j) = u(i+1,j) - d(i,j)*S(i+1,j)/Sp;
            v(i,j) = u(i,j) + d(i,j)*S(i,j-1)/Sp;
            v(i,j+1) = u(i,j+1) - d(i,j)*S(i,j+1)/Sp;
        end
    end


% d = o*(u_{i+1,j} - u_{i,j} + v_{i,j+1} - v_{i,j})   (sobrerelaxa��o, com 1<o<2)
% S = S_{i+1,j} + S_{i-1,j} + S_{i,j+1} + S_{i,j-1}
% u_{i,j}   += d*S_{i-1,j}/S
% u_{i+1,j} -= d*S_{i+1,j}/S
% v_{i,j}   += d*S_{i,j-1}/S
% v_{i,j+1} -= d*S_{i,j+1}/S

    % Fazer um gr�fico
    figure(1),clf
    quiver(graph_X,graph_Y,u,v);


end



