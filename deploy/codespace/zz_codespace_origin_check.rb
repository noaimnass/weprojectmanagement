# frozen_string_literal: true

# GitHub Codespaces rewrites the Origin header of forwarded requests to https://localhost:<port>,
# which fails the CSRF origin comparison on every form submission (login included). Mounted only
# by deploy/docker-compose.codespace.yml; never shipped in the production image.
Rails.application.config.action_controller.forgery_protection_origin_check = false
ActiveSupport.on_load(:action_controller) { self.forgery_protection_origin_check = false }
