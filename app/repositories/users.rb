# frozen_string_literal: true

# Users
class Users < ApplicationRepository
  private

  def default_scope
    User.all
  end

  def filter_by_q(search)
    @scope.where("users.email ILIKE '%#{search}%'")
  end
end
