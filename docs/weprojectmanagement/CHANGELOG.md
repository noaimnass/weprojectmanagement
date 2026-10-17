# Journal des modifications WeProjectManagement

Base : `opf/openproject`, branche `dev`, commit `de387b5d` (17 octobre 2026).

## 1.0.0 — 17 octobre 2026

### Identité et thème
- Logos et icônes WeProjectManagement (`app/assets/images/logo_weprojectmanagement*.png`, `icon_weprojectmanagement*.svg`, touch icon, favicon, `public/favicon.ico`, `publiccode_logo.svg`) ; références mises à jour dans `app/helpers/custom_styles_helper.rb`, `app/models/exports/pdf/common/logo.rb`, `config/initializers/lookbook.rb`.
- Thèmes violets : `lib/open_project/custom_styles/color_themes.rb` (« WeProjectManagement Violet (default) », « Clair », « Sombre ») et variables CSS par défaut `frontend/src/global_styles/openproject/_variable_defaults.scss` (mode clair et sombre).
- Courriels (`app/views/mailer/_mailer_header.html.erb`, `app/views/digest_mailer/work_packages.html.erb`, `app/views/layouts/mailer.html.erb`) et thèmes d'export PDF (`standard.yml`) aux couleurs de la marque.
- Titre par défaut « WeProjectManagement » (`config/constants/settings/definition.rb`) ; liens site et contact vers weworld.tech (`config/static_links.yml`).
- Nom produit remplacé dans les textes d'interface EN et FR (`config/locales/en.yml`, `js-en.yml`, `crowdin/fr.yml`, `crowdin/js-fr.yml`), en conservant les mentions d'OpenProject GmbH, de l'édition Enterprise, de la communauté et des URL. Les autres langues restent celles d'OpenProject.
- README produit (`README.md`), ancien README conservé (`README.openproject.md`), documentation `docs/weprojectmanagement/`, pile de production `deploy/`.

### Module Pilotage (`modules/pilotage`, nouveau)
- Engine, permissions (globales et projet), menus global / projet / administration, paramètres (`pilotage_*`), module projet activé par défaut.
- Tables `pilotage_entities`, `pilotage_project_profiles`, `pilotage_register_items`, `pilotage_milestone_reviews`, `pilotage_status_reports`, `pilotage_project_requests`, `pilotage_instances`, `pilotage_sessions`.
- Services : classification et éligibilité, cycle de vie, signaux (avec agrégats en lot), résumé de portefeuille, master plan, plan de charge, indicateurs du dispositif, mon espace, conversion de demande, export et import CSV.
- Pages : cockpit, PMO 360, master plan, plan de charge, conformité, registres (projet et portefeuille), revues de jalon, rapports d'avancement, demandes de projet, organisation 360, gouvernance (instances, séances, agenda, relevé de décisions), référentiel, administration ; vues imprimables (Tour de contrôle, rapport exécutif, flash report).
- Tâches `rake pilotage:seed_governance`, `pilotage:enable_all`, `pilotage:demo`.
- Styles `modules/pilotage/app/components/pilotage/_pilotage.sass` importés dans `frontend/src/global_styles/openproject.sass`.
- Enregistrement dans `Gemfile.modules` et `Gemfile.lock`.

### Relecture indépendante (corrections intégrées)
- Déclarations `options` des composants scindées (défauts dans un appel séparé), constante `Pilotage::Exports::CSV` conforme à l'inflexion Zeitwerk, `workspace_type` et contrôle de la permission « Créer des projets » lors de la conversion d'une demande, bouton d'impression sans gestionnaire inline (CSP), analyse YAML robuste des libellés de jalons, normalisation du code d'entité, références aux utilisateurs enregistrées pour la suppression de comptes, clés étrangères en `on_delete: :nullify` (lots, réunions, projets convertis), périmètre de visibilité appliqué sur la page d'une entité, classification A/B/C recalculée seulement quand la classe n'est pas fixée à la main, validation des rapports possible sans être membre du projet.

### Non modifié volontairement
- Le mécanisme de jeton Enterprise d'OpenProject GmbH et le code des add-ons Enterprise.
- Les espaces de noms Ruby `OpenProject::…`, les migrations et l'API v3 du socle.
