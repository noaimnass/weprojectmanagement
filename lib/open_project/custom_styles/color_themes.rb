# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
# WeProjectManagement is a derivative work by WeWorld Tech (weworld.tech).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject::CustomStyles
  module ColorThemes
    module_function

    OpenProject::CustomStyles::ColorThemes::DEFAULT_THEME_NAME = "WeProjectManagement Violet (default)".freeze

    DEPRECATED_ALTERNATIVE_COLOR = "#35C53F".freeze
    DEPRECATED_PRIMARY_COLOR = "#1A67A3".freeze
    DEPRECATED_BIM_ALTERNATIVE_COLOR = "#349939".freeze
    DEPRECATED_PRIMARY_DARK_COLOR = "#175A8E".freeze
    DEPRECATED_LINK_COLOR = "#155282".freeze
    DEPRECATED_MAIN_MENU_COLOR = "#333739".freeze

    # weworld brand palette
    WEWORLD_VIOLET = "#6C2BD9".freeze
    WEWORLD_VIOLET_DARK = "#4C1D95".freeze
    WEWORLD_VIOLET_DEEP = "#2E1065".freeze
    WEWORLD_VIOLET_SOFT = "#F3EEFC".freeze

    PRIMER_PRIMARY_BUTTON_COLOR = "#7C3AED".freeze
    ACCENT_COLOR = WEWORLD_VIOLET

    THEMES = [
      {
        theme: OpenProject::CustomStyles::ColorThemes::DEFAULT_THEME_NAME,
        colors: {
          "primary-button-color" => PRIMER_PRIMARY_BUTTON_COLOR,
          "accent-color" => ACCENT_COLOR,
          "header-bg-color" => WEWORLD_VIOLET,
          "main-menu-bg-color" => "#FFFFFF",
          "main-menu-bg-selected-background" => WEWORLD_VIOLET_DARK
        }
      },
      {
        theme: "WeProjectManagement Clair",
        colors: {
          "primary-button-color" => PRIMER_PRIMARY_BUTTON_COLOR,
          "accent-color" => ACCENT_COLOR,
          "header-bg-color" => "#FAFAFA",
          "main-menu-bg-color" => WEWORLD_VIOLET_SOFT,
          "main-menu-bg-selected-background" => WEWORLD_VIOLET
        },
        logo: "logo_weprojectmanagement.png"
      },
      {
        theme: "WeProjectManagement Sombre",
        colors: {
          "primary-button-color" => PRIMER_PRIMARY_BUTTON_COLOR,
          "accent-color" => ACCENT_COLOR,
          "header-bg-color" => "#1B1030",
          "main-menu-bg-color" => WEWORLD_VIOLET_DEEP,
          "main-menu-bg-selected-background" => WEWORLD_VIOLET
        }
      }
    ].freeze

    def themes
      THEMES
    end
  end
end
