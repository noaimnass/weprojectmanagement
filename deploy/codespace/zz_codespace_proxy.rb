# frozen_string_literal: true

# Mounted only by deploy/docker-compose.codespace.yml; never shipped in the production image.
# The GitHub Codespaces proxy hands requests to the container with Host: localhost:8080 and an
# Origin of https://localhost:8080; Apache then appends that host to X-Forwarded-Host, so Rails
# would build every redirect on "localhost". Restore the public host before anything else runs.
class CodespaceProxyHeaders
  def initialize(app, host)
    @app = app
    @host = host
  end

  def call(env)
    env["HTTP_HOST"] = @host
    env["HTTP_X_FORWARDED_HOST"] = @host
    env["HTTP_X_FORWARDED_PROTO"] = "https"
    env["HTTP_X_FORWARDED_PORT"] = "443"
    env["HTTP_ORIGIN"] = "https://#{@host}" if env["HTTP_ORIGIN"].to_s.include?("localhost")
    @app.call(env)
  end
end

public_host = ENV["OPENPROJECT_HOST__NAME"].to_s
if public_host.present? && public_host != "localhost:8080"
  Rails.application.config.middleware.insert_before(0, CodespaceProxyHeaders, public_host)
end

Rails.application.config.action_controller.forgery_protection_origin_check = false
ActiveSupport.on_load(:action_controller_base) { self.forgery_protection_origin_check = false }
