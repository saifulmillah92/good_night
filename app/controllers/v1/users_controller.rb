# frozen_string_literal: true

module V1
  class UsersController < V1::ResourceController
    def index
      result = service.all(params)
      render_json_array result[:result],
                        default_output,
                        use: format,
                        current_user: current_user,
                        followeds: result[:followeds],
                        total: total_count
    end

    def follows
      input = V1::FollowCreationInput.new(params)
      validate! input

      service.follow(input.output)
      render_ok message: t("follows.follow_success")
    end

    def unfollows
      service.unfollow(params[:user_id])
      render_ok message: t("follows.unfollow_success")
    end

    private

    def service
      UserService.new(current_user)
    end
  end
end
