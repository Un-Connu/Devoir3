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