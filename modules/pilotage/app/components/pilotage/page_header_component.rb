# frozen_string_literal: true

#-- copyright
# WeProjectManagement — Pilotage module, by WeWorld Tech (weworld.tech).
# Copyright (C) WeWorld Tech
#
# WeProjectManagement is a derivative work of OpenProject.
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module Pilotage
  class PageHeaderComponent < ApplicationComponent
    include ApplicationHelper

    options :title, :project, :description, :actions, breadcrumbs: []

    def breadcrumb_items
      items = []
      if project.present?
        items << { href: url_helpers.project_overview_path(project.id), text: project.name }
        items << { href: url_helpers.project_pilotage_cockpit_path(project), text: I18n.t("pilotage.label_pilotage") }
      else
        items << { href: url_helpers.pilotage_cockpit_path, text: I18n.t("pilotage.label_pilotage") }
      end
      items.concat(Array(breadcrumbs))
      items << title
      items
    end
  end
end
