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
#    - nom: Mouchaimech
#      prenom: Kazem
#      matricule: 20232897
#      github: Kaz1711
#    - nom: 
#      prenom: 
#      matricule:
#      github:
# ---

# # Introduction

# ## Mise en contexte

# Les maladies infectieuses asymtpomatiques représentent un défi majeur pour la
# santé publique, car les individus infectés peuvent transmettre la maladie sans
# être détectés, ce qui oblige les stratégies de contrôle à utiliser des tests
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

# Nous faisons l’hypothèse qu’une stratégie À AJOUTER !!!!!!!!!!

# # Description du modèle

# # Code pour le modèle

# Nous allons simuler le comportement d'une épidémie, qui se transmet par
# contact direct, et qui entraîne la mort après un intervale de temps fixe.

# importation des bibliothèques nécessaires pour la simulation
# CairoMakie : visualisation et graphiques
# StatsBase : fonctions statistiques
# Random : génération de nombres aléatoires

using CairoMakie
CairoMakie.activate!(px_per_unit=6.0)

using StatsBase

# fixe la graine pour que les simulations soient reproductibles.
import Random
Random.seed!(1234)

# Puisque nous allons identifier des agents, nous utiliserons des UUIDs pour
# leur donner un indentifiant unique:

import UUIDs
UUIDs.uuid4()

# ## Création des types

# Structure representant un individu dans la simulation
# chaque agent possède:
# - une position (x, y) dans le paysage
# - un compteur de temps avant la mort (clock)
# - le moment ou le vaccin a été administré (timevacc)
# - des états booléens indiquant si l'agent est infectieux, vacciné, surveillé ou en quarantaine

Base.@kwdef mutable struct Agent
    x::Int64 = 0                       # position x de l'agent
    y::Int64 = 0                       # position y de l'agent
    clock::Int64 = 20                  # durée restante de l'infection (en jours)
    timevacc::Int64 = 0                # moment ou le vaccin a été administré
    infectious::Bool = false           # indique si l'agent est infecté
    vaccinated::Bool = false           # indique si l'agent est vacciné
    surveiller::Bool = false           # indique si l'agent est surveillé
    quarantined::Bool = false          # indique si l'agent est en quarantaine
    id::UUIDs.UUID = UUIDs.uuid4()     # identifiant unique de l'agent
end

# On peut créer un agent pour vérifier:

Agent()

# structure representant le paysage dans lequel les agents se déplacent
# le paysage est défini par des limites sur x et y

Base.@kwdef mutable struct Landscape
    xmin::Int64 = -25
    xmax::Int64 = 25
    ymin::Int64 = -25
    ymax::Int64 = 25
end

# création du paysage initial:

L = Landscape(xmin=-50, xmax=50, ymin=-50, ymax=50)

# ## Création de nouvelles fonctions

#Méthode permettant de créer un agent à une position aléatoire dans le paysage

Random.rand(::Type{Agent}, L::Landscape) = Agent(x=rand(L.xmin:L.xmax), y=rand(L.ymin:L.ymax))

# Méthode permettant de créer plusieurs agents  

Random.rand(::Type{Agent}, L::Landscape, n::Int64) = [rand(Agent, L) for _ in 1:n]

# Cette fonction nous permet donc de générer un nouvel agent dans un paysage:

rand(Agent, L)

# Mais aussi de générer plusieurs agents:

rand(Agent, L, 3)

# Fonction qui déplace un agent d'une case aléatoire dans la grille
# si torus=true, les bords du paysage sont connectés (effet torus)
# sinon, les agents restent dans les limites du paysage

function move!(A::Agent, L::Landscape; torus=true)

    # déplacement aléatoire
    A.x += rand(-1:1)
    A.y += rand(-1:1)

    if torus
        # effet torus: les agents qui sortent d'un bord réapparaissent de l'autre côté
        A.y = A.y < L.ymin ? L.ymax : A.y
        A.x = A.x < L.xmin ? L.xmax : A.x
        A.y = A.y > L.ymax ? L.ymin : A.y
        A.x = A.x > L.xmax ? L.xmin : A.x
    else
        # limite classique: les agents restent dans les limites du paysage
        A.y = A.y < L.ymin ? L.ymin : A.y
        A.x = A.x < L.xmin ? L.xmin : A.x
        A.y = A.y > L.ymax ? L.ymax : A.y
        A.x = A.x > L.xmax ? L.xmax : A.x
    end
    return A
end

# On test et vaccine les gens dans un disque autour du premier mort



# Nous pouvons maintenant définir des fonctions qui vont nous permettre de nous
# simplifier la rédaction du code:

# vérifier si un agent est infectieux:
isinfectious(agent::Agent) = agent.infectious

# vérifier si un agent est sain:

ishealthy(agent::Agent) = !isinfectious(agent)

# vérifier si un agent est vacciné:
isvaccinated(agent::Agent) = agent.vaccinated

# vérifier si un agent est non vacciné:
isunvaccinated(agent::Agent)=!isvaccinated(agent)

# vérifier si un agent est surveillé:
issurveiller(agent::Agent)= agent.surveiller

# vérifier si un agent est en quarantaine:
isquarantined(agent::Agent)= agent.quarantined

# vérifier si un agent peut se déplacer:
ismoving(agent::Agent)= !isquarantined(agent)

# On peut maintenant définir une fonction pour prendre uniquement les agents qui
# sont infectieux dans une population. Pour que ce soit clair, nous allons créer
# un _alias_, `Population`, qui voudra dire `Vector{Agent}`:

const Population = Vector{Agent}

# Fonctions permettant de filtrer les agents d'une population selon leur état
# Chaque fonction retourne un sous-ensemble de la population contenant uniquement
# les agents qui satisfont la condition:

infectious(pop::Population) = filter(isinfectious, pop)
healthy(pop::Population) = filter(ishealthy, pop)
vaccinated(pop::Population) = filter(isvaccinated, pop)
unvaccinated(pop::Population)=filter(isunvaccinated, pop)
surveiller(pop::Population)=filter(issurveiller, pop)
moving(pop::Population)=filter(ismoving, pop)
quarantined(pop::Population)=filter(isquarantined, pop)

# Fonction qui retourne les agents qui sont dans la même cellule que l'agent cible.
# Cela permet d'idetifier les agents qui peuvent entrer en contact direct avec cette cible.

incell(target::Agent, pop::Population) = filter(ag -> (ag.x, ag.y) == (target.x, target.y), pop)

# ## Paramètres initiaux

# Fonction permettant de créer une population initiale.

function Population(L::Landscape, n::Integer)
    return rand(Agent, L, n)
end

# Fonction permettant d'afficher une population d'une manière plus lisible dans la console.

Base.show(io::IO, ::MIME"text/plain", p::Population) = print(io, "Une population avec $(length(p)) agents")

# Paramètres globaux de la simulation:

tick = 0             # temps actuel de la simulation
maxlength = 2000     # nombre maximal de générations
budget= 21000        # budget total pour les tests et les vaccins
distance = 25        # rayon de surveillance autour des agents morts

# Stockage des événements d'infection

struct InfectionEvent
    time::Int64         # moment de l'infection
    from::UUIDs.UUID    # identifiant de l'agent infectieux
    to::UUIDs.UUID      # identifiant de l'agent infecté
    x::Int64            # coordonnée x de l'infection
    y::Int64            # coordonnée y de l'infection
end

# Stockage des événements de vaccination

struct VaccinEvent
    time::Int64         # moment de la vaccination
    to::UUIDs.UUID      # identifiant de l'agent vacciné
    x::Int64            # coordonnée x de la vaccination
    y::Int64            # coordonnée y de la vaccination
end

# Stockage des agents morts

struct DeadAgent
    time::Int64         # moment de la mort
    to::UUIDs.UUID      # identifiant de l'agent mort
    x::Int64            # coordonnée x de la mort
    y::Int64            # coordonnée y de la mort
end

# Notez qu'on a contraint notre vecteur `events` a ne contenir _que_ des valeurs
# du bon type, et que nos `InfectionEvent` sont immutables.

# ## Simulation
# nombre de simulations à faire
test = 10            

# Matrice pour stocker les résultats de chaque simulation
suivi = zeros(3,10)

for i in 1:test

    # initilisation des paramètres globaux pour chaque simulation

    tick = 0           # temps courant de la simulation
    maxlength = 2000   # durée maximale de générations
    budget= 21000      # budget total pour les tests et les vaccins
    distance = 25      # rayon de surveillance autour d'un décès

    # génération de la population initiale
    population = Population(L, 3750)

    # sélection aléatoire d'un agent pour être le patient zéro
    rand(population).infectious = true

    # Tableaux pour suivre l'évolution de la population
    # S= susceptibles, I=infectieux, R=recovered
    S = zeros(Int64, maxlength);
    I = zeros(Int64, maxlength);
    R = zeros(Int64, maxlength);

    # vecteurs permettant de stocker les événements de la simulation
    events = InfectionEvent[]
    eventsvaccin = VaccinEvent[]
    dead = DeadAgent[]


    # Boucle principale de la simulation
    while (length(infectious(population)) != 0) & (tick < maxlength)

        ## Mise à jour du temps de la simulation
        global tick, population, budget, distance
        tick += 1

        ## Si un décès est observé, on place en surveillance
        ## tous les agents dans un rayon de distance autour du décès
        if !isempty(dead)  
        centre = dead[1] 

            for agent in population
                if ((agent.x - centre.x)^2 + (agent.y - centre.y)^2) <= (distance)^2
                    agent.surveiller = true      ## les agents dans le rayon sont marqués comme surveillés
                    agent.quarantined = true     ## les agents dans le rayon sont mis en quarantaine
                end
            end
        end

        ## Déplacement des agents qui ne sont pas en quarantaine
        for agent in moving(population)
            move!(agent, L; torus=false)
        end    

        ## progression de la maladie chez les agents infectieux
        for agent in infectious(population)
            agent.clock -= 1                 ## la durée de vie de l'agent diminue
        end

        ## activation du vaccin après 2 jours
        for agent in vaccinated(population)
            if tick >= (agent.timevacc)+2
                agent.infectious=false       ## l'agent n'est plus infectieux
                agent.quarantined=false      ## l'agent n'est plus en quarantaine 
            end
        end

        ## fin de la quarantaine après 20 jours
        for agent in quarantined(population)
            if tick >= (centre.time)+20
                agent.quarantined=false
            end
        end

        ## transmission de la maladie par contact direct
        for agent in Random.shuffle(infectious(population))
            neighbors = healthy(incell(agent, population))
            for neighbor in neighbors
                if rand() <= 0.4 && neighbor.vaccinated == false
                    neighbor.infectious = true
                    push!(events, InfectionEvent(tick, agent.id, neighbor.id, agent.x, agent.y))
                end
            end
        end
        
        ## si un décès est observé, mise en place de la stratégie de vaccination
        if !isempty(dead) ## Si il y a un mort
   
        ## test des agents sains sous surveillance
            for agent in intersect(healthy(population), surveiller(population)) ## On ne peut pas utiliser && combiné avec "for agent in..."
                if budget >= 4
                    budget-=4
                
                    if rand() >= 0.95
                        if budget >=17
                            agent.vaccinated = true
                            push!(eventsvaccin, VaccinEvent(tick, agent.id, agent.x, agent.y))
                            agent.timevacc=tick
                            budget-=17

                            ## Vaccination des voisins dans la même cellule
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

            ## test des agents infectieux sous surveillance
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

        ## Suppression des agents morts de la population
        for agent in population
            if agent.clock < 0
                push!(dead, DeadAgent(tick, agent.id, agent.x, agent.y))
                population = filter(x -> x.clock > 0, population)
            end
        end

        ## Stockage des tailles de population à chaque génération
        S[tick] = length(filter(isunvaccinated,healthy(population)))
        I[tick] = length(infectious(population))
        R[tick] = length(filter(isvaccinated,healthy(population)))

    end

    ## Stockage des résultats final de la simulation
    suivi[1, i] = length(population)
    suivi[2, i] = length(vaccinated(population))
    suivi[3, i] = budget

end

# Affichage des résultats globaux des simulations
print(suivi)

# # Résultat des simulations et discussion

# ## Présentation des résultats

# ### Série temporelle

# couper les séries temporelles au moment de la dernière génération
# simulée pour éviter les valeurs inutiles
S = S[1:tick];
I = I[1:tick];
R = R[1:tick];

# création d'un graphique montrant l'évolution des populations
# susceptibles (S), infectieux (I) et vaccinés (R) au cours du temps

f = Figure()
ax = Axis(f[1, 1]; xlabel="Génération", ylabel="Population")
stairs!(ax, 1:tick, S, label="Susceptibles", color=:black)
stairs!(ax, 1:tick, I, label="Infectieux", color=:red)
stairs!(ax, 1:tick, R, label="Recovered", color=:blue)
axislegend(ax)
current_figure()

# ### Nombre de cas par individu infectieux

# Analyser combien d'infections ont été causées par chaque agent infectieux

# comptage le nombre d'infections générées par chaque agent
infxn_by_uuid = countmap([event.from for event in events]);

# comptage de nombre de vaccination 
vaccincount = countmap([event.to for event in eventsvaccin]);

# La commande `countmap` renvoie un dictionnaire, qui associe chaque UUID au
# nombre de fois ou il apparaît:

length(infxn_by_uuid)            # nombre d'agents ayant causé au moins une infection
length(vaccincount)              # nombre d'agents ayant été vaccinés
length(population)               # taille finale de la population
length(surveiller(population))   # nombre d'agents ayant été mis en surveillance

# distribution du nombre d'infections causées par les agents infectieux:
nb_inxfn = countmap(values(infxn_by_uuid))

# visualidation de la distribution du nombre d'infections causées par les agents infectieux
f = Figure()
ax = Axis(f[1, 1]; xlabel="Nombre d'infections", ylabel="Nombre d'agents")
scatterlines!(ax, [get(nb_inxfn, i, 0) for i in Base.OneTo(maximum(keys(nb_inxfn)))], color=:black)
f

# ### Hotspots

# analyse de la propagation spatiotemporelle des infections.
# on extrait le temps et la position de chaque événement d'infection.
t = [event.time for event in events];
pos = [(event.x, event.y) for event in events];

#visualisation de la propagation spatiotemporelle des infections
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
