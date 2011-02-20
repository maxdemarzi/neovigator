require 'rubygems'
require 'neography'
require 'sinatra/base'
require 'uri'

class Neovigator < Sinatra::Base
  set :haml, :format => :html5 
  set :app_file, __FILE__

  include Neography

  configure do
    env = ENV['NEO4J_ENV'] || "development"
    $stderr.puts env
    if env == "development"
      require 'net-http-spy'
      Net::HTTP.http_logger_options = {:verbose => true} 
    end

    Config.server = ENV['NEO4J_HOST'] || "neography.org"
#   Config.directory = '/' + (ENV['NEO4J_INSTANCE'] || "")
#   Config.authentication = "basic"
#   Config.username = ENV['NEO4J_LOGIN'] || ""
#   Config.password = ENV['NEO4J_PASSWORD']|| ""
  end


  before do
    @neo = Neography::Rest.new
  end

  helpers do
    def link_to(url, text=url, opts={})
      attributes = ""
      opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
      "<a href=\"#{url}\" #{attributes}>#{text}</a>"
    end
  end

  
  get '/resources/show' do
    content_type :json

    @node = {:details_html => "<h2>Fluency with information technology</h2>\n<p class='summary'>\nthere's no description for this topic yet.\n[\n<a href='http://freebase.com/view/soft/isbn/9780321268464/best' target='_new'>Freebase Topic</a>\n]\n</p>\n",
             :data => {:attributes => [{:values => [], :name => "Number of pages", :id => "/book/book_edition/number_of_pages"},
                                        {:values => [{:name => "Fluency with Information Technology", :id => "/en/fluency_with_information_technology"}], :name => "Edition Of", :id => "/book/book_edition/book"},
                                        {:values => [{:name => "Lawrence Snyder", :id => "/en/lawrence_snyder"}], :name => "Author/editor", :id => "/book/book_edition/author_editor"},
                                        {:values => [{:name => "9780321268464", :id => "/soft/isbn/9780321268464"}], :name => "ISBN", :id => "/book/book_edition/isbn"}],
                        :name => "Fluency with information technology",
                        :id => "/soft/isbn/9780321268464/best"}
            }

    @node.to_json

  end

  get '/' do
    @neoid = params["neoid"]
    haml :index
  end

end