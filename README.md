## Projet d'équipe : Mise à niveau de l'application Smart-Meter

**Cours :** MGL7320 - Ingénierie Logicielle des Systèmes d'Intelligence Artificielle  
**Enseignant :** Laurent Yves Magnin  
**Courriel :** [magnin.laurent_yves@uqam.ca](mailto:magnin.laurent_yves@uqam.ca)  

**Organisation GitHub :** [![uqam-lomagnin][![uqam-lomagnin](https://img.shields.io/badge/GitHub-Org-blue)]](https://github.com/uqam-lomagnin)  
**Nom de l'équipe :** [![r00tAI][![uqam-lomagnin](https://img.shields.io/badge/GitHub-Org-blue)]](https://github.com/orgs/uqam-lomagnin/teams/r00tai)  
**GitHub de notre projet :** [![smartmeter-r00tai][![uqam-lomagnin](https://img.shields.io/badge/GitHub-Org-blue)]](https://github.com/uqam-lomagnin/smartmeter-r00tai)  

---

## Membres de l'équipe

| Nom et prénom                   | Courriel étudiant                            | Nom d'utilisateur GitHub           | Programme d'études                                             |
|---------------------------------|----------------------------------------------|------------------------------------|----------------------------------------------------------------|
| Francois Gonothi Toure           | toure.francois_gonothi@courrier.uqam.ca     | @gtfrans2re                        | Maîtrise en informatique (systèmes électroniques)               |
| Ben Bachir Aboubakar Nabil       | aboubakar_nabil.ben_bachir@courrier.uqam.ca | @BenBachirAboubakarNabil           | Maîtrise en génie logiciel                                      |
| Martial Zachee Kaljob Kollo      | kaljob_kollo.martial_zachee@courrier.uqam.ca | @kaljob                            | Maîtrise en informatique pour l'intelligence et la gestion des données |
| Sokhna Mariame Ndour             | ndour.sokhna_mariame@courrier.uqam.ca       | @zeyda97                           | Maîtrise en informatique (intelligence artificielle)           |

## Architecture

### Architecture Globale

#### Vue d'ensemble de l'architecture Smart-Meter.
- L’architecture repose sur une intégration fluide des composants suivants :

  - **Locust** : Simule les données des compteurs intelligents pour les tests de charge.
  - **Kafka** : Transmet les données entre les différentes applications Spark.
  - **Apache Spark** : Traite les données et effectue des prédictions.
  - **HDFS** : Stocke les données transformées dans un Data Lake.
  - **MLflow** : Gère les modèles de machine learning.
  - **Prometheus & Grafana** : Collectent et visualisent les métriques des composants.
  - **Airflow** : Orchestration des pipelines de traitement et de prévision des données.

![Architecture Smart-Meter](images/architecture.png)


#### Orchestration avec Airflow
Airflow est utilisé pour orchestrer les pipelines de traitement et prédiction. Les DAGs d’Airflow automatisent les tâches suivantes :

  - Collecte des données via Kafka.
  - Traitement des données par les applications Spark.
  - Sauvegarde des modèles entraînés dans MLflow.
  - Poussée des métriques vers Prometheus.

Accès à l’interface web d’Airflow : http://localhost:9095
![img.png](img.png)

### Surveillance des métriques
La surveillance est assurée par Prometheus et Grafana, permettant une vision en temps réel des performances du système.

Prometheus collecte les métriques des applications Spark, Locust, Kafka, et Airflow.

Accès : http://localhost:9090

### Grafana
Accès : http://localhost:3000
![grafana.jpeg](images%2Fgrafana.jpeg)


**Note** : Nous avons travaillé intensément pour la mise a niveau de ce projet, mais avec le temps alloue qui est court, il a été difficile pour nous de finaliser la configuration de Prometheus avec les autres composants. En conséquence, nous n’avons pas pu exporter toutes les métriques ni les afficher dans Grafana. Malgré cela, nous avons assuré une base solide pour le suivi des métriques.

