# frozen_string_literal: true

# UserService
class UserService < AppService
  def initialize(user)
    super(user, User, Users.new)
  end

  def follow(params)
    target_user = find(params[:followed_id])
    assert! !@user.followed_relationships.exists?(followed_id: target_user.id),
            on_error: t("follows.already_following")

    transaction do
      Follow.create!(follower_id: @user.id, followed_id: target_user.id)
    end
  end

  def unfollow(followed_id)
    target_user = find(followed_id)
    assert! @user.followed_relationships.exists?(followed_id: target_user.id),
            on_error: t("follows.not_following")

    @user.followeds.destroy(target_user)
  end
end
