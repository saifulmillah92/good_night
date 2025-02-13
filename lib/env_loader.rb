# frozen_string_literal: true

module EnvLoader
  def self.load
    application_yml_file = Rails.root.join("config/application.yml")
    return unless File.exist?(application_yml_file)

    config_env = YAML.safe_load(File.read(application_yml_file))
    config_env.each { |key, value| ENV[key.to_s] = value }
  end
end
