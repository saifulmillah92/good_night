# frozen_string_literal: true

Dir[Rails.root.join("spec/factories/**/*.rb")].sort.each do |file|
  require file
end

RSpec.configure { |config| config.include Factories }
