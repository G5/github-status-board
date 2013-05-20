require 'sinatra/auth/github'
require 'octokit'
require 'uri'

module G5
  class StatusBoard < Sinatra::Base

    CLIENT_ID = ENV['G5_CLIENT_ID']
    CLIENT_SECRET = ENV['G5_SECRET_KEY']
    HOST = 'http://g5-status-board.herokuapp.com'

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
          "g5-theme-garden" => client.pull_requests("g5search/g5-theme-garden"),
          "g5-layout-garden" => client.pull_requests("g5search/g5-layout-garden"),
        }

        # pull_requests = {}
        #
        # repos.each do |repo|
        #   if !client.pull_requests("g5search/#{repo.name}").empty?
        #     pull_requests[repo.name] = client.pull_requests("g5search/#{repo.name}")
        #   end
        # end

        erb :index, :locals => {:repos => repos, :pull_requests => pull_requests}
      end
    end

    def refresh_link
      hidden_repos = params[:hidden_repos] || ''
      refresh = params[:refresh] || ''
      link_start = "<a id='refresh' href='#{HOST}"
      link_classes = 'btn btn-small'
      link_params = ''
      link_text = ''
      full_link = ''

      if refresh == 'true'
        refresh = ''
        link_text = 'Turn Off Auto Refresh'
      else
        refresh = 'true'
        link_classes += ' btn-info'
        link_text = 'Turn On Auto Refresh'
      end

      if !hidden_repos.empty? && !refresh.empty?
        full_link = "#{link_start}?hidden_repos=#{hidden_repos}&refresh=#{refresh}' class='#{link_classes}'>#{link_text}</a>"
      elsif hidden_repos.empty? && !refresh.empty?
        full_link = "#{link_start}?refresh=#{refresh}' class='#{link_classes}'>#{link_text}</a>"
      elsif refresh.empty? && !hidden_repos.empty?
        full_link = "#{link_start}?hidden_repos=#{hidden_repos}' class='#{link_classes}'>#{link_text}</a>"
      else
        full_link = "#{link_start}' class='#{link_classes}'>#{link_text}</a>"
      end

      full_link

    end

    def show_hide_link(repo)
      if params[:refresh] && params[:refresh] == 'true'
        refresh = '&refresh=true'
      else
        refresh = ''
      end

      hidden_repos = params[:hidden_repos] || ''
      hidden_repos = hidden_repos.split(',')

      link_start = "<a href='#{HOST}"
      link_end = "' />Hide</a>"

      if hidden_repos.include? repo
        hidden_repos.delete(repo)
      else
        hidden_repos << repo
      end

      hidden_repos = hidden_repos.join(',')

      full_link = "#{link_start}?hidden_repos=#{hidden_repos}#{refresh}#{link_end}"
      full_link
    end

    def show_repo?(repo)
      hidden_repos = params[:hidden_repos] || ''
      hidden_repos = hidden_repos.split(',')
      if hidden_repos.include? repo
        return false
      else
        return true
      end
    end

    def show_all_repos
      refresh = params[:refresh] || ''
      if refresh == 'true'
        '<a href="#{HOST}?refresh=true" class="btn btn-large btn-primary">Show all repos</a>'
      else
        '<a href="#{HOST}" class="btn btn-large btn-primary">Show all repos</a>'
      end
    end

  end
end
