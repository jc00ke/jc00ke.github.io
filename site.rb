%w(rubygems sinatra haml sass rack-flash).each { |r| require r }

set :haml,          { :format => :html5 }
set :sessions,      true
use Rack::Flash,    :accessorize => [ :notice, :error ]

get '/' do
    haml :index
end

get '/styles.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :styles
end
