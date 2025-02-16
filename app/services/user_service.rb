# frozen_string_literal: true

# UserService
class UserService < AppService
  def initialize(user)
    super(user, User, Users.new)
  end

  def all(query = {})
    result = super
    followeds = followed_relationships.where(followed_id: result.pluck(:id))
                                      .index_by(&:followed_id)

    { result: result, followeds: followeds }
  end

  def follow(params)
    target_user = find(params[:followed_id])
    followed_relationships.create!(followed_id: target_user.id)
  rescue ActiveRecord::RecordNotUnique
    raise UniqueViolation, t("follows.already_following")
  end

  def unfollow(followed_id)
    target_user = find(followed_id)
    assert! followed_relationships.exists?(followed_id: target_user.id),
            on_error: t("follows.not_following")

    @user.followeds.destroy(target_user)
  end

  private

  def followed_relationships
    @followed_relationships ||= @user.followed_relationships
  end
end
