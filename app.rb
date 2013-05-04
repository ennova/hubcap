require 'sinatra'
require 'sinatra/partial'

require 'project'
require 'helpers'

class App < Sinatra::Base
  register Sinatra::Partial
  enable :partial_underscores

  helpers ApplicationHelpers

  use Rack::Auth::Basic, 'Restricted Area' do |username, password|
    username == 'admin' and password == ENV['PASSWORD']
  end

  get '/' do
    haml :work_board
  end

  get '/release-board' do
    haml :release_board
  end

  get '/user-board' do
    haml :user_board
  end

  get '/refresh' do
    project.clear
    redirect request.referrer || '/'
  end
end
