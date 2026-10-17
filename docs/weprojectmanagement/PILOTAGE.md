# Module Pilotage — guide fonctionnel

Le module Pilotage apporte à WeProjectManagement la couche de pilotage de portefeuille d'un Transformation Office / PMO : il s'appuie sur les projets, lots de travaux, jalons, budgets et réunions du socle, et y ajoute la méthode (cycle de vie, classes, signaux, gouvernance).

## Navigation

- **Menu global › Pilotage** : Cockpit, PMO 360, Master plan, Plan de charge, Conformité du reporting, Registres (vue portefeuille), Demandes de projet, Organisation 360, Gouvernance, Rapports, Référentiel.
- **Menu projet › Pilotage** : Cockpit du projet, Registres, Revues de jalon, Rapports d'avancement, fiche de pilotage et flash report.
- **Administration › Pilotage** : paramètres de la méthode.

## Droits

| Permission | Portée | Pour qui |
|---|---|---|
| Consulter le pilotage du portefeuille | globale | Direction, PMO, correspondants, sponsors (lecture) |
| Animer le pilotage du portefeuille | globale | PMO central : validation des rapports, qualification et décision des demandes, organisation, instances et séances, relances |
| Consulter le pilotage du projet | projet | Membres du projet |
| Gérer le pilotage du projet | projet | Chef de projet : fiche, registres, jalons, rapports |

Le module projet « Pilotage » est activé par défaut dans les nouveaux projets ; `rake pilotage:enable_all` l'active sur les projets existants.

## Fiche de pilotage du projet

Catégorie, classe (A/B/C, calculée depuis le budget et le nombre d'entités si laissée par défaut), portefeuille, programme, axe stratégique, entité pilote, sponsor, chef de projet, correspondant PMO, budget total / engagé / dépensé, phase P0–P8, santé déclarée, dates de début, fin et fin de référence, rattachement financier (OTP SAP, code projet…), objectifs et périmètre.

Si le module Budgets du socle est activé et renseigné, ses montants priment sur ceux de la fiche pour le signal budget.

## Cycle de vie et revues de jalon

Cycle commun **P0 Demande qualifiée → P1 Cadrage → P2 Lancement → P3 Conception → P4 Réalisation → P5 Recette → P6 Go/No-Go → P7 Mise en service → P8 Clôture**. Les libellés s'adaptent par catégorie (administration, YAML). « Créer les jalons P0–P8 » répartit les dates entre le début et la fin du projet ; chaque revue porte date planifiée, prévisionnelle et réelle, décision (à tenir, Go, Go conditionnel, No-Go), lien facultatif vers un lot de travaux de type jalon. Un Go enregistre la date réelle et fait passer le projet à la phase suivante.

## Signaux et santé

Quatre signaux calculés par projet, règles détaillées dans le Référentiel :

- **Délais** : retard du jalon le plus ancien non tenu, écart entre fin prévue et fin de référence, part des lots ouverts en retard.
- **Budget** : consommation rapportée à l'avancement moyen des lots.
- **Risques** : criticité maximale (probabilité × impact, 1 à 5) des risques ouverts.
- **Reporting** : ancienneté du dernier rapport validé par rapport à la cadence de la classe (A hebdomadaire, B bimensuelle, C mensuelle par défaut).

La **santé calculée** est le pire des quatre ; la **santé déclarée** vient du dernier rapport validé. Déclaré vert avec signaux rouges = **faux vert**, mis en avant partout.

## Registres

Neuf registres par projet, consolidables au niveau portefeuille : risques, problèmes, décisions, actions, demandes de changement, livrables, bénéfices, parties prenantes, impacts du changement. Référence automatique (R-001, I-001, D-001, A-001, C-001, L-001, B-001, S-001, M-001), statut, priorité, responsable, échéance, champs spécifiques par registre (plans de traitement, instance et séance d'une décision, impacts délais/budget/périmètre, phase et version d'un livrable, indicateur/cible/mesure d'un bénéfice, entité et influence d'une partie prenante, population et niveau d'un impact).

**Export CSV** (UTF-8, point-virgule) et **import CSV** : le fichier exporté sert de modèle ; les références existantes mettent à jour, les autres créent ; un bilan (créations, mises à jour, erreurs) précède toute écriture.

## Rapports d'avancement

Le chef de projet crée un rapport (période, santé, signaux délais/budget/périmètre/risques, avancement, synthèse, faits marquants, prochaines étapes, décisions attendues) pré-rempli à partir des signaux calculés, l'enregistre en brouillon ou le soumet. Le PMO valide ou renvoie ; **un membre du PMO ne valide pas sa propre mise à jour**. La validation met à jour la santé déclarée du projet et alimente la conformité du reporting.

## Cockpit et PMO 360

- **Cockpit** : compteurs (projets, rouges, orange, faux verts, avancement moyen, jalons en retard, rapports à valider, budget), météo par signal, projets critiques, horizon glissant (45 jours par défaut), arbitrages (décisions attendues, demandes de changement, demandes de projet), Mon espace (mes tâches, mes actions, validations à faire, prochaines séances), indicateurs du dispositif.
- **PMO 360** : table filtrable (recherche, catégorie, classe, entité, santé) et regroupable (catégorie, classe, portefeuille, programme, entité, axe, phase), export CSV.
- **Master plan** : SVG, une ligne par projet, phases entre jalons, trait de référence, ligne « aujourd'hui », écart de fin.
- **Plan de charge** : heures par personne et par mois sur douze mois, à partir des heures estimées des lots ouverts réparties entre début et fin ; surcharge au-delà de la capacité paramétrée.
- **Conformité du reporting** : cadence, dernier rapport validé, ancienneté, signal ; « Relancer » crée une action de relance (registre Actions) chez le correspondant ou le chef de projet des projets en retard.

## Demandes de projet

Formulaire (titre, description, entité, catégorie, axe, budget, durée, entités, bénéfices) → **soumise** → **qualifiée** par le PMO (éligibilité : budget ≥ 0,5 unité, durée ≥ 3 mois ou ≥ 2 entités ; classe suggérée) → **Go / No-Go** en Tour de contrôle → **conversion** en projet P0 avec sa fiche de pilotage (modules par défaut + Pilotage).

## Organisation 360

Arborescence d'entités (organisation, direction, département, pôle, école, service, unité) avec code, responsable, effectif, budget, centre de coûts, référence externe (Workday, SAP…). Fiche 360 : projets pilotés (avec signaux), projets qui transforment l'entité (registre Impacts), parties prenantes, bénéfices, demandes de projet, plan de charge.

## Gouvernance

Instances en cascade (comité projet → revue de portefeuille → Tour de contrôle → comité stratégique) avec périodicité et président ; séances (ordre du jour, relevé, projet et réunion du socle associés, état) ; agenda mensuel (séances et jalons planifiés, reporting à produire) ; relevé de décisions consolidé, filtrable par instance.

## Rapports

- **Dossier Tour de contrôle** (9 pages, format paysage) : couverture, situation et points clés, projets critiques et faux verts, santé par ensemble, arbitrages, jalons à l'horizon, demandes de projet, conformité et indicateurs, décisions à compléter en séance.
- **Rapport exécutif** : situation, master plan, vue d'ensemble des projets avec dernière synthèse validée, risques majeurs et indicateurs.
- **Flash report** d'un projet (une page).

Les rapports s'ouvrent dans une vue imprimable (bouton « Imprimer / PDF ») ; les registres et le portefeuille s'exportent en CSV, lisible par Excel.

## Indicateurs du dispositif

Reporting à jour, validations sous 2 jours, jalons tenus, rattachement financier des projets de classe A, bénéfices mesurés des projets de classe A, faux verts, délai moyen de décision des demandes, correspondants désignés — avec cibles.

## Paramétrage

Administration › Pilotage : devise, montant de l'unité budgétaire (1 000 000 par défaut : les seuils sont en millions), horizon glissant, capacité mensuelle, seuils d'éligibilité, seuils des classes A et B, cadences A/B/C, catégories, axes stratégiques, libellés des jalons par catégorie (YAML).

## Données de démonstration

`rake pilotage:seed_governance` crée les quatre instances ; `rake pilotage:demo` crée des entités, remplit les fiches, jalons, registres, rapports et deux demandes de projet sur les projets où le module est activé. À réserver aux instances de démonstration.
