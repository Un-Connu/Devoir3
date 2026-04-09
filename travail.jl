# # Introduction

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

# Dans ce contexte, la question posée est : quelle stratégie de dépistage et de 
# vaccination permet de minimiser la mortalité sous contraintes budgétaires ? 
# Nous faisons l’hypothèse qu’une stratégie de dépistage et de vaccination ciblée autour
# du premier décès, avec un rayon progressivement élargi, permettra de réduire 
# efficacement la mortalité tout en optimisant l'utilisation du budget.

# # Modèle et implémentation

# Nous utilisons un modèle basé sur des agents implémenté en Julia, où chaque
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
# temporelles (S, I, R) permettent de suivre la dynamique de l’épidémie.

# Une stratégie d’intervention est appliquée après le premier décès, en ciblant
# les individus autour du foyer d’infection afin de limiter la propagation.

using CairoMakie
CairoMakie.activate!(px_per_unit=6.0)
using StatsBase
import Random

# Puisque nous allons identifier des agents, nous utiliserons des UUIDs pour
# leur donner un indentifiant unique:

import UUIDs
UUIDs.uuid4()

# ## Création des types

# Le premier type que nous avons besoin de créer est un agent. Les agents se
# déplacent sur une lattice, et on doit donc suivre leur position. On doit
# savoir si ils sont infectieux, et dans ce cas, combien de jours il leur reste:

Base.@kwdef mutable struct Agent
    x::Int64 = 0
    y::Int64 = 0
    clock::Int64 = 20
    timevacc::Int64 = 0
    infectious::Bool = false
    vaccinated::Bool = false
    id::UUIDs.UUID = UUIDs.uuid4()
end

# On peut créer un agent pour vérifier:


Agent()

# La deuxième structure dont nous aurons besoin est un paysage, qui est défini
# par les coordonnées min/max sur les axes x et y:

Base.@kwdef mutable struct Landscape
    xmin::Int64 = -25
    xmax::Int64 = 25
    ymin::Int64 = -25
    ymax::Int64 = 25
end

# Nous allons maintenant créer un paysage de départ:

L = Landscape(xmin=-50, xmax=50, ymin=-50, ymax=50)

# ## Création de nouvelles fonctions

# On va commencer par générer une fonction pour créer des agents au hasard. Il
# existe une fonction pour faire ceci dans _Julia_: `rand`. Pour que notre code
# soit facile a comprendre, nous allons donc ajouter une méthode à cette
# fonction:

Random.rand(::Type{Agent}, L::Landscape) = Agent(x=rand(L.xmin:L.xmax), y=rand(L.ymin:L.ymax))
Random.rand(::Type{Agent}, L::Landscape, n::Int64) = [rand(Agent, L) for _ in 1:n]

# Cette fonction nous permet donc de générer un nouvel agent dans un paysage:

rand(Agent, L)

# Mais aussi de générer plusieurs agents:

rand(Agent, L, 3)

# On peut maintenant exprimer l'opération de déplacer un agent dans le paysage.
# Puisque la position de l'agent va changer, notre fonction se termine par `!`:


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

# Nous pouvons maintenant définir des fonctions qui vont nous permettre de nous
# simplifier la rédaction du code. Par exemple, on peut vérifier si un agent est
# infectieux:

isinfectious(agent::Agent) = agent.infectious

# Et on peut donc vérifier si un agent est sain:

ishealthy(agent::Agent) = !isinfectious(agent)

# vaccinné
isvaccinated(agent::Agent) = agent.vaccinated
isunvaccinated(agent::Agent)=!isvaccinated(agent)


# On peut maintenant définir une fonction pour prendre uniquement les agents qui
# sont infectieux dans une population. Pour que ce soit clair, nous allons créer
# un _alias_, `Population`, qui voudra dire `Vector{Agent}`:

const Population = Vector{Agent}

infectious(pop::Population) = filter(isinfectious, pop)
healthy(pop::Population) = filter(ishealthy, pop)
vaccinated(pop::Population) = filter(isvaccinated, pop)
unvaccinated(pop::Population)=filter(isunvaccinated, pop)

# Nous allons enfin écrire une fonction pour trouver l'ensemble des agents d'une
# population qui sont dans la même cellule qu'un agent:

incell(target::Agent, pop::Population) = filter(ag -> (ag.x, ag.y) == (target.x, target.y), pop)

# ## Paramètres initiaux

# Notez qu'on peut réutiliser notre _alias_ pour écrire une fonction beaucoup plus
# expressive pour générer une population:

function Population(L::Landscape, n::Integer)
    return rand(Agent, L, n)
end

# On en profite pour simplifier l'affichage de cette population:

Base.show(io::IO, ::MIME"text/plain", p::Population) = print(io, "Une population avec $(length(p)) agents")

# Et on génère notre population initiale:

population = Population(L, 3750)

# Pour commencer la simulation, il faut identifier un cas index, que nous allons
# choisir au hasard dans la population:

rand(population).infectious = true

# Nous initialisons la simulation au temps 0, et nous allons la laisser se
# dérouler au plus 1000 pas de temps:

tick = 0
maxlength = 2000
budget= 21000

# Pour étudier les résultats de la simulation, nous allons stocker la taille de
# populations à chaque pas de temps:

S = zeros(Int64, maxlength);
I = zeros(Int64, maxlength);
R = zeros(Int64, maxlength);

# Mais nous allons aussi stocker tous les évènements d'infection qui ont lieu
# pendant la simulation:

struct InfectionEvent
    time::Int64
    from::UUIDs.UUID
    to::UUIDs.UUID
    x::Int64
    y::Int64
end

struct VaccinEvent
    time::Int64
    to::UUIDs.UUID
    x::Int64
    y::Int64
end


events = InfectionEvent[]
eventsvaccin = VaccinEvent[]

# Notez qu'on a contraint notre vecteur `events` a ne contenir _que_ des valeurs
# du bon type, et que nos `InfectionEvent` sont immutables.

# ## Simulation

while (length(infectious(population)) != 0) & (tick < maxlength)

    ## On spécifie que nous utilisons les variables définies plus haut
    global tick, population

    tick += 1

    ## Movement
    for agent in population
        move!(agent, L; torus=false)
    end    

    ## Change in survival
    for agent in infectious(population)
        agent.clock -= 1
    end

  ## Change in vaccination effect
    for agent in vaccinated(population)
        if tick >= (agent.timevacc)+2
            agent.infectious=false
        end
    end

    for agent in Random.shuffle(infectious(population))
        neighbors = unvaccinated(incell(agent, population))
        for neighbor in neighbors
            if rand() <= 0.4
                neighbor.infectious = true
                push!(events, InfectionEvent(tick, agent.id, neighbor.id, agent.x, agent.y))
            end
        end
    end

    ## Remove agents that died
    population = filter(x -> x.clock > 0, population)

if length(population) == 3749
    # test RAT    
            if budget >= 4
                    for agent in healthy(population)
                        budget=(budget-4)
                        if rand() >= 0.95
                            if budget >=17
                                agent.vaccinated = true
                                push!(eventsvaccin, VaccinEvent(tick, agent.id, agent.x, agent.y))
                                agent.timevacc=tick
                                budget = (budget-17)
                            end
                        end
                    end
                    for agent in infectious(population)
                        budget=(budget-4)
                        if rand() <= 0.95
                            if budget >= 17
                                agent.vaccinated = true
                                push!(eventsvaccin, VaccinEvent(tick, agent.id, agent.x, agent.y))
                                agent.timevacc=tick
                                budget = (budget-17)
                            end
                        end
                    end
            end
        
    end


    ## Store population size
    S[tick] = length(filter(isunvaccinated,healthy(population)))
    I[tick] = length(infectious(population))
    R[tick] = length(filter(isvaccinated,healthy(population)))

end


# ## Analyse des résultats

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
vaccincount = countmap([event.to for event in eventsvaccin])

# La commande `countmap` renvoie un dictionnaire, qui associe chaque UUID au
# nombre de fois ou il apparaît:

# Notez que ceci nous indique combien d'individus ont été infectieux au total:

length(infxn_by_uuid)
length(vaccincount)

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

# # Modifications possibles

# Pendant le cours, formulez des hypothèses sur l'effet de 

# - la taille du paysage
# - la taille de la population
# - la dispersion sur une lattice toroïdale
# - la durée de l'épidémie
# - la survie de la population

# Étudiez le code en profondeur avant de commencer. Est-ce que certains
# paramètres sont représentés par des _magic numbers_ qui devraient être rendu
# explicites?

# Testez ces hypothèses en variant les paramètres du modèle. Est-ce qu'il existe
# des situations dans lesquelles la population est protégée contre l'épidémie?
# Des situations dans laquelle la structure spatiale de l'épidémie change?

# # Figures supplémentaires

# Visualisation des infections sur l'axe x

scatter(t, first.(pos), color=:black, alpha=0.5)

# et y

scatter(t, last.(pos), color=:black, alpha=0.5)
