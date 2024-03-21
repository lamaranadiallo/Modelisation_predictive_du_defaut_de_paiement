# Modelisation predictive du defaut de paiement

# Introduction
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

---
The project involves modeling data on credit card holders from a North American financial institution. The main objective of the modeling is to estimate the probability that a credit card holder will fail to pay their outstanding balance (default) within a future 12-month horizon after collecting various model features. A customer is considered to be in default if at least one of the following conditions is met during the specified period (12 months after a given date used to collect the variables):
- Payment delay of 90 days or more;
- Bankruptcy
- Removal;
It should be mentioned that this is modeling of an existing credit card holder base (the financial institution has enough information in terms of behavior: these are the different variables describing this customer base). Thus, the modeling will involve predicting the behavior of a holder in a future 12-month horizon based on their current and past behavior. The resulting model is therefore a behavioral model that will track over time the behavior of credit card holders in terms of their ability to repay the outstanding balance by the date required by the financial institution.