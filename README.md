# Séance de présentation de projets d'équipe

**Date :** Mardi 12 novembre 2024  
**Lieu :** SH-3560, Pavillon Sherbrooke, Faculté des Sciences de l'UQAM  

## Projet d'équipe : Mise à niveau de l'application Smart-Meter

**Cours :** MGL7320 - Ingénierie Logicielle des Systèmes d'Intelligence Artificielle  
**Enseignant :** Laurent Yves Magnin  
**Courriel :** [magnin.laurent_yves@uqam.ca](mailto:magnin.laurent_yves@uqam.ca)  

**Organisation GitHub :** [uqam-lomagnin](https://github.com/uqam-lomagnin)  
**Nom de l'équipe :** [r00tAI](https://github.com/orgs/uqam-lomagnin/teams/r00tai)  
**GitHub de notre projet :** [smartmeter-r00tai](https://github.com/uqam-lomagnin/smartmeter-r00tai)  

---

## Membres de l'équipe

| Nom et prénom                   | Courriel étudiant                            | Nom d'utilisateur GitHub           | Programme d'études                                             |
|---------------------------------|----------------------------------------------|------------------------------------|----------------------------------------------------------------|
| Francois Gonothi Toure           | toure.francois_gonothi@courrier.uqam.ca     | @gtfrans2re                        | Maîtrise en informatique (systèmes électroniques)               |
| Ben Bachir Aboubakar Nabil       | aboubakar_nabil.ben_bachir@courrier.uqam.ca | @BenBachirAboubakarNabil           | Maîtrise en génie logiciel                                      |
| Martial Zachee Kaljob Kollo      | kaljob_kollo.martial_zachee@courrier.uqam.ca | @kaljob                            | Maîtrise en informatique pour l'intelligence et la gestion des données |
| Sokhna Mariame Ndour             | ndour.sokhna_mariame@courrier.uqam.ca       | @zeyda97                           | Maîtrise en informatique (intelligence artificielle)           |

---

## Table des matières
- [Aperçu du projet](#aperçu-du-projet)
- [Exigences](#exigences)
- [Spécifications](#spécifications)
- [Architecture](#architecture)
- [Plan de développement prévu](#plan-de-développement-prévu)
- [Présentation des outils](#présentation-des-outils)
- [Source de données](#source-de-données)
- [Conclusion](#conclusion)

---

## Project Overview
L'objectif de ce projet est de moderniser l'application Smart-Meter, en résolvant les dettes techniques et en améliorant sa documentation pour une utilisation et un déploiement simplifiés. Nous avons entrepris une refonte totale de l'architecture, en intégrant de nouvelles technologies et en optimisant la collecte et l'analyse des données en temps réel des compteurs intelligents.

## Exigences
Le projet doit répondre aux critères suivants :
- Respect des principes d'ingénierie logicielle pour la manipulation des données des systèmes d'intelligence artificielle.
- Capacité de gestion des flux de données en temps réel à partir des sources de tension et de température.
- Documentation complète pour faciliter la compréhension de l'architecture, du déploiement et de l'utilisation de l'application.

## Specifications
Notre version modernisée de l'application inclut :
- **Traitement des données** : Capacité de traitement en temps réel des données de tension et de température.
- **Modèle de prédiction** : Utilisation d'un modèle ML pour prédire les anomalies de tension basées sur les données recueillies.
- **Visualisation** : Interface Grafana pour visualiser les données et les prédictions en temps réel.
- **Évolutivité** : Architecture permettant d'étendre facilement le nombre de capteurs ou de compteurs intelligents connectés.

## Architecture
Notre architecture suit un modèle distribué basé sur Docker et Kubernetes pour garantir la portabilité et l'évolutivité.

![Architecture Smart-Meter](images/smartmeter-architecture.png)

- **Source de données** : Les capteurs de tension et de température.
- **Ingestion et Transformation des données** : Utilisation d'Apache Kafka pour l'ingestion en temps réel.
- **Stockage des données** : Utilisation de Cassandra pour les données brutes et de InfluxDB pour les données agrégées.
- **Module d'analyse** : Modèles de machine learning dans Apache Spark pour les prédictions et les anomalies.
- **Visualisation** : Tableau de bord Grafana pour afficher les métriques en temps réel.

## Plan de développement prévu
Nous avons organisé notre travail à l'aide de Jira et suivi un diagramme de Gantt pour le développement :

![Jira Screenshot](images/jira-screenshot.png)  
![Gantt Chart](images/gantt-chart.png)

---

## Présentation des outils
- **Docker et Kubernetes** : Conteneurisation et orchestration de l'infrastructure pour une gestion optimale.
- **Grafana** : Visualisation en temps réel des métriques.
- **Apache Kafka** : Gestion des flux de données et ingestion en temps réel.
- **Apache Cassandra** : Base de données NoSQL pour stocker les données brutes de tension.
- **Apache Spark** : Traitement des données et analyse prédictive.
- **Python** : Langage pour le développement de l'interface CLI et du traitement des données.

## Source de données
- **Tension** : Les données de tension proviennent des compteurs intelligents.
- **Température** : Les données de température et/ou d'humidité proviennent de capteurs environnementaux.

## Installation et emplacement des Smart Meters
Les smart meters sont installés dans des résidences et locaux spécifiques pour recueillir des données de consommation d'énergie et environnementales.

---

## Conclusion
La refonte de l'application Smart-Meter permet non seulement de réduire la dette technique mais aussi d'offrir une solution plus performante et évolutive pour la gestion et l'analyse des données de compteurs intelligents.