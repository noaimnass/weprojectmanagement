# Licence, marques et jeton Enterprise

## Ce qu'autorise la GPL v3

OpenProject est publié sous GNU GPL v3. La licence autorise à copier, modifier et redistribuer le logiciel, à condition de :

1. **Conserver la licence** : le dérivé reste sous GPL v3 (`LICENSE`), avec les mentions de copyright d'OpenProject GmbH, ChiliProject et Redmine (`COPYRIGHT`, en-têtes des fichiers). Les en-têtes ajoutés par WeWorld Tech mentionnent la filiation.
2. **Fournir le code source** à toute personne à qui le logiciel est distribué (binaire, image Docker, installation chez un client). L'usage en SaaS interne sans distribution n'oblige pas à publier, mais la pratique recommandée est de garder ce dépôt accessible aux clients.
3. **Signaler les modifications** : ce dossier et `docs/weprojectmanagement/CHANGELOG.md` décrivent ce qui a changé par rapport à OpenProject.

## Marques

« OpenProject » et le logo OpenProject sont des marques d'OpenProject GmbH : un dérivé modifié ne doit pas se présenter comme OpenProject. C'est pourquoi le produit est renommé **WeProjectManagement**, avec son propre logo et son thème ; les mentions « OpenProject » qui subsistent dans l'interface désignent l'éditeur du socle (OpenProject GmbH, communauté, documentation, édition Enterprise) et sont exactes.

Les espaces de noms du code (`OpenProject::…`) sont conservés : ils ne sont pas visibles des utilisateurs et évitent de diverger du dépôt amont, ce qui facilite les mises à jour.

## Jeton Enterprise

Les add-ons Enterprise (SSO, LDAP groupes, comparaison de référence, actions personnalisées, planificateur d'équipe, gestion de portefeuille Enterprise, etc.) sont développés par OpenProject GmbH et activés par un **jeton** saisi dans Administration › Édition Enterprise (essai gratuit puis abonnement). WeProjectManagement n'altère pas ce mécanisme : les clients qui souhaitent ces add-ons acquièrent le jeton auprès d'OpenProject GmbH.

La valeur premium propre à WeProjectManagement est le module **Pilotage** (`modules/pilotage`), écrit par WeWorld Tech et livré sous GPL v3 avec le reste.

## Mises à jour depuis OpenProject

Le fork a été réalisé à partir de `opf/openproject` (branche `dev`, 17 octobre 2026). Pour suivre les versions d'OpenProject : ajouter le dépôt amont comme remote, fusionner, puis réappliquer si besoin les modifications listées dans le journal (fichiers de marque, locales, thème, `Gemfile.modules`, `openproject.sass`).
