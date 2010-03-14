%w(rubygems sinatra/base haml sass rack-flash yaml json).each { |r| require r }

class Site < Sinatra::Base

    set :haml,          { :format => :html5 }
    set :sessions,      true
    enable :static
    use Rack::Static,   :urls => %w(/images /javascripts /docs), :root => 'public'
    use Rack::Flash,    :accessorize => [ :notice, :error ]

    configure :development do
        Sinatra::Application.reset!
        use Rack::Reloader
    end

    before do

        @title =    case request.path_info
                    when '/'
                        'Welcome!'
                    when '/resume'
                        'My Resume/CV/Experience'
                    when '/contact'
                        "Let's chat"
                    else
                        'Where are you?'
                    end
    end

    helpers do

        def get_yaml
            File.open('public/docs/resume.yml') { |y| YAML::load y }
        end

    end

    get '/' do
        haml :index
    end

    get '/styles.css' do
        content_type 'text/css', :charset => 'utf-8'
        sass :styles
    end

    get '/resume' do
        @resume = get_yaml
        @info   = @resume['info']
        haml :resume
    end

    get %r{/resume.(yml|json|pdf)} do |ft|
        if ft == 'yml' || ft == 'pdf'
            send_file "public/docs/resume.#{ft}"
        else
            yml     = get_yaml
            content_type 'text/json'
            attachment 'resume.json'
            JSON.pretty_generate yml
        end
    end

    get '/contact' do
        haml :contact
    end

    not_found do
        haml :not_found
    end

    error do
        haml :error
    end

end
