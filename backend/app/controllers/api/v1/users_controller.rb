# frozen_string_literal: true
require "github_api/client"
include GithubAPI

module Api
  module V1
    class UsersController < ApiController
      def index
        github_client = GithubAPI::Client.new(ENV['GITHUB_TOKEN'])
        begin
          user = github_client.get_user(user_params)
          repos = github_client.get_user_repos(user_params, { per_page: 100, sort: 'updated' })
        rescue GithubAPI::Error => error
          render json: error.to_json, status: error.status
          return
        end

        db_user = User.find_or_create_by(github_id: user['id'])
        db_user.update(user.clone.keep_if { |k, _v| User.editable_columns.include? k.to_sym })
        db_user.sync_repositories(repos)
        Repository.reindex

        render json: db_user
      end

      private

      def user_params
        params.require(:username)
      end
    end
  end
end
