require 'sinatra/auth/github'
require 'octokit'

module Example
  class MyBasicApp < Sinatra::Base

    CLIENT_ID = ENV['G5_CLIENT_ID']
    CLIENT_SECRET = ENV['G5_SECRET_ID']

    enable :sessions

    set :github_options, {
      :scopes    => "repo",
      :secret    => CLIENT_SECRET,
      :client_id => CLIENT_ID,
      :callback_url => "/",
    }

    register Sinatra::Auth::Github

    get '/' do
      if !authenticated?
        authenticate!
      else
        client = Octokit::Client.new(
          :login => github_user.login,
          :oauth_token => github_user.token,
          :auto_traversal => true
        )
        repos = client.organization_repositories('g5search', {:type => 'private'})
        pull_requests = {
          "g5-client-hub" => client.pull_requests("g5search/g5-client-hub"),
          "g5-widget-garden" => client.pull_requests("g5search/g5-widget-garden"),
        }
        # repos.each do |repo|
        #   if !client.pull_requests("g5search/#{repo.name}").empty?
        #     pull_requests[repo.name] = client.pull_requests("g5search/#{repo.name}")
        #   end
        # end
        erb :index, :locals => {:repos => repos, :pull_requests => pull_requests}
      end
    end
  end
end