# frozen_string_literal: true

# UserService
class UserService < AppService
  def initialize(user)
    super(user, User, Users.new)
  end
end
