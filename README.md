# Dépôt modèle pour le cours BIO 2045

## Organisation du projet

## Consignes

Modifiez le modèle sur la dynamique épidémique pour simuler une campagne de vaccination.

Vous devrez travailler avec les contraintes suivantes:


    La simulation a lieu sur une lattice de taille -50,50 sur les deux dimensions


    La taille de la population est 3750 individus à l'origine de la simulation


    Le taux d'infection (probabilité de devenir infectieux par contact) est de 0.4


    La durée de la maladie est de 21 jours, et la maladie est toujours fatale


    La population est initialement naïve (pas d'immunité)


    On dispose d'un vaccin contre la maladie qui est entièrement efficace (plus d'infection, plus de mortalité, plus de possibilité de redevenir infectieux)


    Le vaccin n'est actif que deux jours (2 générations) après l'innoculation


    Les individus infectieux sont asymptomatiques (il faut faire un test pour détecter l'infection)


    On dispose d'un test antigénique rapide (RAT) qui permet de détecter les individus infectieux avec une efficacité de 95% (le test se trompe seulement dans 5% des cas)


    Le RAT ne permet pas de savoir depuis quand un individu est infectieux


    Vous ne pouvez pas connaître la prévalence de la maladie dans la population autrement que par des tests


    Une dose de vaccin coûte 17$, l'administration d'un RAT coûte 4$, et vous disposez d'un budget total de 21000$ que vous pouvez utiliser sur des vaccins ou des tests


    Quand le budget est épuisé, vous ne pouvez plus tester / vacciner

    Vous ne pouvez pas commencer a tester/vacciner avant le décès du premier cas

En utilisant le modèle de rapport fourni pour le devoir, présentez les simulations que vous effectuez pour établir votre campagne de vaccination. Le modèle de rapport a été mis à jour, vous devez utiliser la nouvelle version, et lire attentivement l'ensemble des instructions!

Vous devrez modifier le modèle pour refléter la vaccination des agents, et modifier la simulation pour mettre en place votre stratégie de vaccination.

Vous devez mesurer (i) l'efficacité de votre campagne, via la réduction de la mortalité comparée à l'absence d'intervention, et (ii) le coût total de votre campagne.

Critères d'évaluation:

Le code est exécuté sans erreur (2 points)

Le code est organisé sous forme de fonctions documentées (3 points)

Les variables et fonctions sont nommées de manière explicite (3 points)

Tous les blocs de code sont accompagnés par du texte (5 points)

Les packages sont installés dans le Project.toml, pas dans le code lui-même (2 points)

Le travail est rendu sous format PDF dans le format requis (2 points)

Le rapport contient une bibliographie (3 points)

Les modifications du modèle sont expliquées d'un point de vue biologique (4 points)

Les modifications du code du modèle sont expliquées (4 points)

L'introduction présente le problème biologique (3 points)

L'introduction résume les contraintes de la simulation, et ces contraintes sont justifiées (5 points), avec des références à de la littérature scientifique pertinente (2 points)

Présence d'une section sur la stratégie de vaccination, qui explique comment la décision de tester/vacciner est prise (5 points)

Les résultats du modèle sont présentés sous forme de figures (4 points)

Les simulations sont répliquées plusieurs fois (4 points) et leur variabilité est discutée (3 points)

Les résultats du modèle sont présentés dans le texte (4 points), et cette présentation n'est pas une discussion des résultats (3 points)

La discussion des résultats revient sur les concepts abordés dans l'introduction (3 points)

Les limites du modèle sont discutées dans le contexte spécifique de maladies infectieuses identifiées, et cette discussion à la littérature scientifique (6 points)

Toutes les figures du rapport sont nécessaires (3 points)

## Résumé du projet 

Ce projet présente une simulation stochastique d’une épidémie à l’aide d’un modèle basé sur des agents implémenté en Julia. Chaque individu de la population est représenté par un agent évoluant sur une grille bidimensionnelle, pouvant être susceptible, infectieux ou vacciné.

La maladie se transmet par contact direct avec une probabilité fixe, et les individus infectieux ont une durée de vie limitée. Les cas sont asymptomatiques, ce qui impose l’utilisation de tests de dépistage pour identifier les infections.

Le modèle intègre également une stratégie d’intervention avec dépistage, vaccination et quarantaine, qui commence après la détection du premier décès. Cette stratégie vise les individus dans un rayon autour du foyer d’infection. Les contraintes principales du modèle sont :

- un budget limité pour les tests et la vaccination,
- une efficacité parfaite du vaccin après un délai de 2 jours,
- une mortalité systématique des individus infectés après une durée fixe.

L’objectif de la simulation est d’évaluer quelle stratégie de dépistage et de vaccination permet de minimiser la mortalité sous contraintes budgétaires.

## Répartition du travail
Félix De Carufel
Contribution principale au code de simulation et à son explication.
Younes Benbezza
Contribution principale au code de simulation et à son explication.
Ifaliana Ranaivo Rajaonoarisoa
Rédaction de l’introduction et du README.
Kazem
Documentation des fonctions et rédaction de la section résultats.