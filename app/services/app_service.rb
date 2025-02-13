# frozen_string_literal: true

# AppService
class AppService < ApplicationService
  def initialize(user, service = nil, repository = nil)
    super
    @user = user
    @service = service
    @repository = repository
  end

  def all(query = {})
    @repository.filter(query).limited.to_a
  end

  def find(id)
    @service.find(id)
  end

  def find_by(query = {})
    @service.find_by(query)
  end

  def new(query = {})
    @service.new(query)
  end

  def create(query = {})
    transaction { @service.create!(query) }
  end

  def update(id, query = {})
    record = find(id)
    transaction { record.update!(**query) }
  end

  def destroy(id)
    find(id).destroy!
  end

  def count(params = {})
    @repository.filter(params).count
  end

  def validate!(input)
    return unless input
    raise ActiveRecord::RecordInvalid, input if input.errors.any?
    raise ActiveRecord::RecordInvalid, input unless input.valid?

    input
  end

  class NotFound < ::StandardError
  end

  class Unauthenticated < ::StandardError
  end

  class Unauthorized < ::StandardError
  end

  class Invalid < ::StandardError
  end

  class Throttled < ::StandardError
  end
end
