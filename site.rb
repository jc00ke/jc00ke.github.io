%w(rubygems sinatra/base haml sass rack-flash yaml).each { |r| require r }

class Site < Sinatra::Base

    set :haml,          { :format => :html5 }
    set :sessions,      true
    enable :static
    use Rack::Static,   :urls => %w(/images /javascripts /stylesheets), :root => 'public'
    use Rack::Flash,    :accessorize => [ :notice, :error ]

    configure :development do
        Sinatra::Application.reset!
        use Rack::Reloader
    end

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

end
