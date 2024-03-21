## Introduction

Le projet consiste à modéliser des données sur des détenteurs de cartes de crédit d’une institution
financière Nord- Américaine. L’objectif principal de la modélisation consiste à estimer la probabilité
qu’un détenteur d’une carte de crédit ne parvient pas à payer son solde dû (défaut de paiement)
dans un futur horizon de 12 mois après la date de collecte des différentes caractéristiques du modèle.
Un client est considéré être en défaut de paiement si l’une au moins des conditions suivantes
est vérifiée pendant la période visée (12 mois après une date donnée qui a servi à collecter les
variables):
- Retard de paiement de 90 jours ou plus ;
- Faillite
- Radiation ;
Il faut mentionner que c’est une modélisation d’une clientèle déjà détentrice de cartes de crédit
(l’institution financière dispose assez d’informations en termes de comportement : ce sont les
différentes variables décrivant cette clientèle). Ainsi, la modélisation consistera à prédire le comportement
d’un détenteur dans un futur horizon de 12 mois en se basant sur son comportement
actuel et passé. Le modèle résultant est donc un modèle comportemental qui permettra de suivre,
dans le temps, le comportement des détenteurs de cartes de crédit en termes de capacités de
remboursement du solde dû à la date exigée par l’institution financière.