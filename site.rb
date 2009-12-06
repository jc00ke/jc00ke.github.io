%w(rubygems sinatra haml sass rack-flash yaml).each { |r| require r }

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

get '/resume' do
    @resume = File.open('public/resume.yml') { |y| YAML::load y }
    @info   = @resume['info']
    haml :resume
end

not_found do
    haml :not_found
end

error do
    haml :error
end
