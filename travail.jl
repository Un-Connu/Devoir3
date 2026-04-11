# ---
# title: 
# repository: 
# auteurs:
#    - nom: Benbezza
#      prenom: Younes
#      matricule: 20315516
#      github: Un-Connu
#    - nom: De Carufel
#      prenom: Félix
#      matricule: 20275312
#      github: FelixDeCarufel
#    - nom: Ranaivo Rajaonarisoa
#      prenom: Ifaliana
#      matricule: 20325981
#      github: r-ifaliana
#    - nom: 
#      prenom: 
#      matricule:
#      github:
# ---

# # Introduction

# ## Mise en contexte

# Les maladies infectieuses asymtpomatiques représentent un défi majeur pour la
# santé publique, car les individus infectés peuvent transmettre la maladie sans
# être détectés @Keeling_Eames_2005, ce qui oblige les stratégies de contrôle à utiliser des tests
# de dépistage et les vaccins.

# Dans ce travail, nous utilisons un modèle spatial basé sur des agents afin
# de simuler la propragation d'une maladie infectieuse. Il permet de représenter 
# les interactions entre les individus, ce qui est important car la transmission
# des maladies dépend fortement de la structure des contacts dans le paysage.
# La population est composée de 3750 individus initialement naifs, ce qui correspond
# à l'introduction d'un pathogène dans une population sans immunité, ce qu'on 
# retrouve souvent avant l'émergence d'une épidémie.
# La transmission se fait par contact direct avec une probabilité de 0.4, représentant
# une maladie hautement transmissible. La durée d'infection est fixée à 21 jours,
# ce qui permet aux individus de rester infectieux assez longtemps pour transmettre
# le pathogène. La mortalité systématique nous permet de nous concentrer seulement
# sur l'impact des vaccins sur la mortalité.
# Le caractère asymptomatique des individus malades justifie l'utilisation de test
# pour détecter les malades. Le seuil de risque de 5% pour le test est dû à
# la possibilité d'obtenir des faux-négatifs ou faux-positifs dans la réalité.
# Le vaccin étant parfaitement efficace, nous pourrons mesurer l'efficacité de la
# stratégie sans considérer les variabilités. Le délai de deux jours avant activation
# reflète le temps nécessaire à la réponse immunitaire adaptative.
# Efin, les interventions sont limitées par un budget de 21000$, avec des coûts
# différents pour les tests et la vaccination. Cette contrainte introduit un 
# compromis entre dépistage et prévention, reflétant les limitations réelles des
# systèmes de santé. L’impossibilité de connaître la prévalence sans tests simule 
# les difficultés de surveillance épidémiologique, et le délai avant intervention
# (après le premier décès) représente un temps de détection réaliste.

# ## Question

# Dans ce contexte, la question posée est : quelle stratégie de dépistage et de 
# vaccination permet de minimiser la mortalité sous contraintes budgétaires ?

# ## Hypothèse et résultats attendus

# Nous faisons l’hypothèse qu’une stratégie de dépistage et de vaccination ciblée autour
# du premier décès, avec un rayon progressivement élargi, permettra de réduire 
# efficacement la mortalité tout en optimisant l'utilisation du budget. De plus, nous supposons 
# aussi que la mise en quarantaine de tous les individus dans l’anneau limitera 
# la propagation, avec une durée réduite pour les vaccinés. De plus, vacciner immédiatement les voisins
# directs d’un cas détecté devrait freiner la transmission locale.

# En gros, la stratégie consiste à tester les individus situés dans un cercle autour du premier décès. 
# Si un individu est détecté positif, ses voisins immédiats sont vaccinés. Tous les individus dans l’anneau 
# sont également placés en quarantaine, indépendamment de leur statut. Le rayon du cercle est progressivement 
# augmenté afin d’élargir la zone d’intervention.

# ## Description du modèle

# Nous utilisons un modèle basé sur des agents implémenté en Julia @Eubank_2004 , où chaque
# individu est représenté par une structure `Agent` contenant sa position,
# son état d’infection, son statut vaccinal et un compteur de survie.

# Les agents évoluent dans une lattice bidimensionnelle (-50, 50) et se déplacent
# aléatoirement à chaque pas de temps. La transmission se produit lorsqu’un agent
# infectieux partage la même cellule qu’un agent susceptible, avec une probabilité
# de 0.4.

# Les individus infectieux voient leur compteur diminuer jusqu’à leur mort après
# 21 jours. Les individus vaccinés deviennent protégés après un délai de deux
# générations.

# Les événements d’infection et de vaccination sont enregistrés, et des séries
# temporelles (S, I, R) permettent de suivre la dynamique de l’épidémie @Kermack_McKendrick_1927.

# Une stratégie d’intervention est appliquée après le premier décès, en ciblant
# les individus autour du foyer d’infection afin de limiter la propagation.

# # Code pour le modèle

# Utilisations des packages nécessaires

using CairoMakie
CairoMakie.activate!(px_per_unit=6.0)
using StatsBase
import Random
Random.seed!(1234)

# Puisque nous allons identifier des agents, nous utiliserons des UUIDs pour
# leur donner un indentifiant unique:

import UUIDs
UUIDs.uuid4()

# ## Création des types

# Le premier type que nous avons besoin de créer est un agent. Les agents se déplacent sur une lattice, et on doit donc suivre leur position. 
# On doit savoir si ils sont infectieux, et dans ce cas, combien de jours il leur reste, s'ils sont vaccinés, et dans ce cas, combien de jour
# il reste avant que le vaccin fasse effet, s'ils sont en quarantaine et s'ils sont "à surveiller", soit à proximité du premier mort.

Base.@kwdef mutable struct Agent
    x::Int64 = 0
    y::Int64 = 0
    clock::Int64 = 20
    timevacc::Int64 = 0
    infectious::Bool = false
    vaccinated::Bool = false
    surveiller::Bool = false
    quarantined::Bool = false
    id::UUIDs.UUID = UUIDs.uuid4()
end

# La deuxième structure dont nous aurons besoin est un paysage, qui est défini par les coordonnées min/max sur les axes x et y:

Base.@kwdef mutable struct Landscape
    xmin::Int64 = -25
    xmax::Int64 = 25
    ymin::Int64 = -25
    ymax::Int64 = 25
end

# Nous allons maintenant créer un paysage de départ:

L = Landscape(xmin=-50, xmax=50, ymin=-50, ymax=50)

# ## Création des fonctions

# On va commencer par générer une fonction pour créer des agents au hasard, puis les placer dans le paysage. Pour ce faire, une 
# nouvelle méthode à été ajoutée à la fonction rand().

Random.rand(::Type{Agent}, L::Landscape) = Agent(x=rand(L.xmin:L.xmax), y=rand(L.ymin:L.ymax))
Random.rand(::Type{Agent}, L::Landscape, n::Int64) = [rand(Agent, L) for _ in 1:n]

# Création d'une fonction qui permet de déplacer les agents dans le paysage, avec la possibilité de considérer le paysage comme fermé ou comme
# un torus.

function move!(A::Agent, L::Landscape; torus=true)
    A.x += rand(-1:1)
    A.y += rand(-1:1)
    if torus
        A.y = A.y < L.ymin ? L.ymax : A.y
        A.x = A.x < L.xmin ? L.xmax : A.x
        A.y = A.y > L.ymax ? L.ymin : A.y
        A.x = A.x > L.xmax ? L.xmin : A.x
    else
        A.y = A.y < L.ymin ? L.ymin : A.y
        A.x = A.x < L.xmin ? L.xmin : A.x
        A.y = A.y > L.ymax ? L.ymax : A.y
        A.x = A.x > L.xmax ? L.xmax : A.x
    end
    return A
end

# Créations de plusieurs fonctions pour connaitre les états des agents tant qu'à certains de leur champs. C'est le cas de l'infection, de la
# vaccination, de la proximité au premier mort ("issurveiller") et de la quarantaine.

isinfectious(agent::Agent) = agent.infectious

ishealthy(agent::Agent) = !isinfectious(agent)

isvaccinated(agent::Agent) = agent.vaccinated

isunvaccinated(agent::Agent)=!isvaccinated(agent)

issurveiller(agent::Agent)= agent.surveiller

isquarantined(agent::Agent)= agent.quarantined

ismoving(agent::Agent)= !isquarantined(agent)

# Créations de fonctions qui permettent de sélectionner certains agents dans la poulation sur la base de leurs champs à l'aide des fonctions
# définies précédemment.

const Population = Vector{Agent}

infectious(pop::Population) = filter(isinfectious, pop)
healthy(pop::Population) = filter(ishealthy, pop)
vaccinated(pop::Population) = filter(isvaccinated, pop)
unvaccinated(pop::Population)=filter(isunvaccinated, pop)
surveiller(pop::Population)=filter(issurveiller, pop)
moving(pop::Population)=filter(ismoving, pop)
quarantined(pop::Population)=filter(isquarantined, pop)

# Puisque la contagion se fait par contact entre les agents d'une même cellule, il nous faut une fonction pour savoir quels agents partage une
# cellule.

incell(target::Agent, pop::Population) = filter(ag -> (ag.x, ag.y) == (target.x, target.y), pop)

# Création d'une fonction pour faciliter la génération de populations et simplification de son affichage.

function Population(L::Landscape, n::Integer)
    return rand(Agent, L, n)
end

Base.show(io::IO, ::MIME"text/plain", p::Population) = print(io, "Une population avec $(length(p)) agents")

# ## Paramètres initiaux

# Notre simulation commence au temps 0 et se déroule sur une durée maximale de 2000 générations. On accorde un budget de "budget" afin de
# tester et vacciner les agents dans un rayon de "distance" autour du premier mort. La simulations sera générée un certain nombre de fois, soit
# "test" avec une taille définie par "taille". La probabilité de transmission est définie par "contagion"

tick = 0
maxlength = 2000
budget= 21000
distance = 25
test = 10
taille = 3750
contagion = 0.4

# ## Création de structures

# Nous allons stocker tous les évènements d'infection, de mortalité et de vaccination qui ont lieu pendant la simulation afin de mieux 
# comprendre quand et où ceux-ci sont-ils arrivés.

struct InfectionEvent
    time::Int64
    from::UUIDs.UUID
    to::UUIDs.UUID
    x::Int64
    y::Int64
end
events = InfectionEvent[]

struct VaccinEvent
    time::Int64
    to::UUIDs.UUID
    x::Int64
    y::Int64
end
eventsvaccin = VaccinEvent[]

struct DeadAgent
    time::Int64
    to::UUIDs.UUID
    x::Int64
    y::Int64
end
dead = DeadAgent[]

# ## Simulation

#population = Population(L, taille)

# Le nombre d'individus susceptibles, infecteux et remis seront suivis lors des générations

S = zeros(Int64, maxlength);
I = zeros(Int64, maxlength);
R = zeros(Int64, maxlength);

# La taille de la population vivante, de la population vaccinée et le budget seront enregistrés après chaque simulation

suivi = zeros(3,test);

for i in 1:test

    global tick, population, budget, distance, maxlength, S, I, R, events, eventsvaccin, dead, contagion
    
    ## On s'assure de remettre le conteur de génération, la population et le budget à leur valeur initiale entre chaque simulation

    tick = 0
    budget= 21000
    population = Population(L, taille)

    ## Le premier individu infecté est choisi aléatoirement

    rand(population).infectious = true

    ## Le nombre d'individus susceptibles, infecteux et remis seront suivis lors des générations sont aussi remis à leur valeur initiale

    S = zeros(Int64, maxlength);
    I = zeros(Int64, maxlength);
    R = zeros(Int64, maxlength);

    ## Même chose pour les différents énènements

    events = InfectionEvent[]
    eventsvaccin = VaccinEvent[]
    dead = DeadAgent[]

    ## La simulation à lieu tant et aussi longtemps que la population n'est pas nulle et qu'on a pas atteint la limite de génération choisie

    while (length(infectious(population)) != 0) & (tick < maxlength)

        ## On spécifie que nous utilisons les variables définies plus haut

        global tick, population, budget, distance, maxlength, S, I, R, events, eventsvaccin, dead
        tick += 1

        if !isempty(dead)   ## Si dead n'est pas vide, on mesure la distance entre le mort et chaque agents
        centre = dead[1] ## Puisque dead peut comprendre plus qu'un mort, on prend seulement le premier

        ## On met en quarantaine les agents qui sont à moins d'une certaine ditance du premier mort. Ceux-ci seront à tester et vacciner si nécessaire

            for agent in population
                if ((agent.x - centre.x)^2 + (agent.y - centre.y)^2) <= (distance)^2
                    agent.surveiller = true
                    agent.quarantined = true
                end
            end
        end

        ## Chaque agent qui n'est pas en quarantaine se déplace à chaque génération

        for agent in moving(population)
            move!(agent, L; torus=false)
        end    

        ## Les agents infectés ont une espérence de vie limitée
        
        for agent in infectious(population)
            agent.clock -= 1
        end

        ## Le vaccin prend 2 jours à agir. Une fois que le vaccin fait effet, les agents ne sont plus en quarantaine

        for agent in vaccinated(population)
            if tick >= (agent.timevacc)+2
                agent.infectious=false
                agent.quarantined=false
            end
        end

        ## Si jamais des agents sont testés positifs et ne sont pas vaccinés par manque de budget, on les laisse en quarantaine

        for agent in quarantined(population)
            if tick >= (centre.time)+20
                agent.quarantined=false
            end
        end

        ## Les agents vaccinés ont une certaine chance d'infecter les agents sains non-vaccinés dans leur cellule

        for agent in Random.shuffle(infectious(population))
            neighbors = healthy(incell(agent, population))
            for neighbor in neighbors
                if rand() <= contagion && neighbor.vaccinated == false
                    neighbor.infectious = true
                    push!(events, InfectionEvent(tick, agent.id, neighbor.id, agent.x, agent.y))
                end
            end
        end

        if !isempty(dead)   ## Lorsqu'il y a au moins un agent de mort
   
        ## Parmis les agents qui sont à surveiller, si ceux-ci sont sains il y a 5% de chances de faux positif. Si le budget le permet, un test 
        ## est fait. Si ce dernier indique que les agents doivent être vaccinés et que le budget le permet, ils le seront.  

            for agent in intersect(healthy(population), surveiller(population)) ## On ne peut pas utiliser && combiné avec "for agent in...", ça renvoit un code d'erreur
                if budget >= 4
                    budget-=4
                
                    if rand() >= 0.95
                        if budget >=17
                            agent.vaccinated = true
                            push!(eventsvaccin, VaccinEvent(tick, agent.id, agent.x, agent.y))
                            agent.timevacc=tick
                            budget-=17
                            neighbors = unvaccinated(incell(agent, population))
                            for neighbor in neighbors
                                if budget >= 17
                                    neighbor.vaccinated = true
                                    push!(eventsvaccin, VaccinEvent(tick, neighbor.id, neighbor.x, neighbor.y))
                                    neighbor.timevacc=tick
                                    budget-=17
                                end
                            end
                        end
                    end
                end
            end
        
        ## Parmis les agents qui sont à surveiller, si ceux-ci sont contagieux, il y a 5% de chances de faux négatif. Si le budget le permet,
        ## un test est fait. Si ce dernier indique que les agents doivent être vaccinés et que le budget le permet, ils le seront.  
            for agent in intersect(infectious(population), surveiller(population))
                if budget >= 4
                    budget-=4
                
                    if rand() <= 0.95
                        if budget >= 17
                            agent.vaccinated = true
                            push!(eventsvaccin, VaccinEvent(tick, agent.id, agent.x, agent.y))
                            agent.timevacc=tick
                            budget-=17
                            neighbors = unvaccinated(incell(agent, population))
                            for neighbor in neighbors
                                neighbor.vaccinated = true
                                push!(eventsvaccin, VaccinEvent(tick, neighbor.id, neighbor.x, neighbor.y))
                                neighbor.timevacc=tick
                                budget-=17
                            end
                        end
                    end
                end
            end

        end

        ## Les agents morts sont retirés de la population
    
        for agent in population
            if agent.clock < 0
                push!(dead, DeadAgent(tick, agent.id, agent.x, agent.y))
                population = filter(x -> x.clock > 0, population)
            end
        end

        ## Le suivi des populations saines, infectées et rétablies a lieu

        S[tick] = length(filter(isunvaccinated,healthy(population)))
        I[tick] = length(infectious(population))
        R[tick] = length(filter(isvaccinated,healthy(population)))

    end

    ## La taille de la population vivante, de la population vaccinée et le budget restant sont enregistrés après chaque simulation

    suivi[1, i] = length(population)
    suivi[2, i] = length(vaccinated(population))
    suivi[3, i] = budget

end

print(suivi)

# # Résultat des simulations et discussion

# ## Présentation des résultats

# ### Série temporelle

# Avant toute chose, nous allons couper les séries temporelles au moment de la
# dernière génération:


S = S[1:tick];
I = I[1:tick];
R = R[1:tick];

#-

f = Figure()
ax = Axis(f[1, 1]; xlabel="Génération", ylabel="Population")
stairs!(ax, 1:tick, S, label="Susceptibles", color=:black)
stairs!(ax, 1:tick, I, label="Infectieux", color=:red)
stairs!(ax, 1:tick, R, label="Recovered", color=:blue)
axislegend(ax)
current_figure()

# ### Nombre de cas par individu infectieux

# Nous allons ensuite observer la distribution du nombre de cas créés par chaque
# individus. Pour ceci, nous devons prendre le contenu de `events`, et vérifier
# combien de fois chaque individu est représenté dans le champ `from`:

infxn_by_uuid = countmap([event.from for event in events]);
vaccincount = countmap([event.to for event in eventsvaccin]);

# La commande `countmap` renvoie un dictionnaire, qui associe chaque UUID au
# nombre de fois ou il apparaît:

# Notez que ceci nous indique combien d'individus ont été infectieux au total:

length(infxn_by_uuid)
length(vaccincount)
length(population)
length(surveiller(population))

# Pour savoir combien de fois chaque nombre d'infections apparaît, il faut
# utiliser `countmap` une deuxième fois:

nb_inxfn = countmap(values(infxn_by_uuid))

# On peut maintenant visualiser ces données:

f = Figure()
ax = Axis(f[1, 1]; xlabel="Nombre d'infections", ylabel="Nombre d'agents")
scatterlines!(ax, [get(nb_inxfn, i, 0) for i in Base.OneTo(maximum(keys(nb_inxfn)))], color=:black)
f

# ### Hotspots

# Nous allons enfin nous intéresser à la propagation spatio-temporelle de
# l'épidémie. Pour ceci, nous allons extraire l'information sur le temps et la
# position de chaque infection:

t = [event.time for event in events];
pos = [(event.x, event.y) for event in events];

#

f = Figure()
ax = Axis(f[1, 1]; aspect=1, backgroundcolor=:grey97)
hm = scatter!(ax, pos, color=t, colormap=:navia, strokecolor=:black, strokewidth=1, colorrange=(0, tick), markersize=6)
Colorbar(f[1, 2], hm, label="Time of infection")
hidedecorations!(ax)
current_figure()

# # Figures supplémentaires

# Visualisation des infections sur l'axe x

scatter(t, first.(pos), color=:black, alpha=0.5)

# et y

scatter(t, last.(pos), color=:black, alpha=0.5)

# ## Discussion
# ### Limitations du modèles

# # Références
