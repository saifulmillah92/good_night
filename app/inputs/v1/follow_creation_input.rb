# frozen_string_literal: true

module V1
  class FollowCreationInput < ::ApplicationInput
    strip_unknown_attributes

    required(:user_id)

    output_keys(user_id: :followed_id)

    validate :target_user

    def target_user
      return unless user_id.to_i == Current.current_user.id

      errors.add(:base, t("follows.not_able_to_follow_yourself"))
    end
  end
end
