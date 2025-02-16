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

      result = service.follow(input.output)
      render_json result,
                  status: :created,
                  current_user: current_user,
                  show: true,
                  message: t("follows.follow_success")
    end

    def unfollows
      result = service.unfollow(params[:user_id])
      render_json result,
                  current_user: current_user,
                  show: true,
                  message: t("follows.unfollow_success")
    end

    private

    def service
      UserService.new(current_user)
    end
  end
end
