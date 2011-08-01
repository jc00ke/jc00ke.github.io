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
        @page = request.path_info.gsub(/\//, '')
    end

    helpers do

        def get_yaml
            File.open('public/docs/resume.yml') { |y| YAML::load y }
        end
        def split_url(url)
            txt, url = url.scan(/^(.*)\s\|\s(.*)$/)[0]
            "<a href=\"#{url}\">#{txt}</a>"
        end
        def cache(time=600)
            headers['Cache-Control'] = "public, max-age=#{time}" if Sinatra::Base.production?
        end
    end

    get '/' do
        @title  = "Welcome!"
        cache
        haml :index
    end

    get %r{/(styles|print).css} do |sheet|
        cache(3600)
        content_type 'text/css', :charset => 'utf-8'
        sass sheet.to_sym
    end

    get '/resume' do
        @title  = "My Resume/CV/Experience"
        cache
        haml :resume
    end

    get '/5000' do
        @title = "My 5000th tweet"
        cache(3600)
        haml :'5000'
    end
    get '/contact' do
        @title  = "Let's chat"
        cache(3600)
        haml :contact
    end

    not_found do
        @title  = "Where are you?"
        haml :not_found
    end

    error do
        @title  = "Uh oh, something broke."
        haml :error
    end

end
