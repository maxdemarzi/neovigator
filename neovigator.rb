require 'rubygems'
require 'neography'
require 'sinatra/base'
require 'uri'

class Neovigator < Sinatra::Application
  set :haml, :format => :html5 
  set :app_file, __FILE__

  configure :test do
    require 'net-http-spy'
    Net::HTTP.http_logger_options = {:verbose => true} 
  end

  helpers do
    def link_to(url, text=url, opts={})
      attributes = ""
      opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
      "<a href=\"#{url}\" #{attributes}>#{text}</a>"
    end

    def neo
      @neo = Neography::Rest.new(ENV["GRAPHENEDB_URL"] || "http://neo4j:swordfish@localhost:7474")
    end
  end
  
  def hashify(results)
    results["data"].map {|row| Hash[*results["columns"].zip(row).flatten] }
  end

  def create_graph
    return if neo.execute_query("MATCH (n:Organization) RETURN COUNT(n)")["data"].first.first > 1

    organizations = %w[Farm KFC Pepsi]
    products = %w[chicken_raw chicken_fried softdrinks]
    locations = %w[New\ York\ City Iowa]
      
    cypher = "CREATE (n:Organization {nodes}) RETURN  ID(n) AS id, n.name AS name"
    nodes = []
    organizations.each { |n| nodes <<  {"name" => n} }
    organizations = hashify(neo.execute_query(cypher, {:nodes => nodes}))

    cypher = "CREATE (n:Location {nodes}) RETURN  ID(n) AS id, n.name AS name"
    nodes = []
    locations.each { |n| nodes << {"name" => n} }
    locations = hashify(neo.execute_query(cypher, {:nodes => nodes}))
  
    cypher = "CREATE (n:Product {nodes}) RETURN  ID(n) AS id, n.name AS name"
    nodes = []  
    products.each { |n| nodes << {"name" => n} }
    products = hashify(neo.execute_query(cypher, {:nodes => nodes}))
    
    neo.execute_query("CREATE INDEX ON :Organization(name)")
    neo.execute_query("CREATE INDEX ON :Location(name)")
    neo.execute_query("CREATE INDEX ON :Product(name)")
  
    #C reating relationships manually:
    commands = []
    farm = organizations[0]
    kfc = organizations[1]
    pepsi = organizations[2]
    nyc = locations[0]
    iowa = locations[1]
    chicken_raw = products[0]
    chicken_fried = products[1]
    softdrinks = products[2]
    
    commands << [:create_relationship, "located_in", pepsi["id"], nyc["id"], nil]    
    commands << [:create_relationship, "located_in", kfc["id"], nyc["id"], nil]    
    commands << [:create_relationship, "located_in", farm["id"], iowa["id"], nil]    
    
    commands << [:create_relationship, "makes", farm["id"], chicken_raw["id"], nil]    
    commands << [:create_relationship, "makes", kfc["id"], chicken_fried["id"], nil]    
    commands << [:create_relationship, "makes", pepsi["id"], softdrinks["id"], nil] 
    
    commands << [:create_relationship, "buys", kfc["id"], chicken_raw["id"], nil]        
    commands << [:create_relationship, "buys", pepsi["id"], chicken_fried["id"], nil]        
    commands << [:create_relationship, "buys", kfc["id"], softdrinks["id"], nil]                
    commands << [:create_relationship, "buys", farm["id"], chicken_fried["id"], nil]        
                
    neo.batch *commands

  end

helpers do
    def link_to(url, text=url, opts={})
      attributes = ""
      opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
      "<a href=\"#{url}\" #{attributes}>#{text}</a>"
    end
  end

  def node_id(node)
    case node
      when Hash
        node["self"].split('/').last
      when String
        node.split('/').last
      else
        node
    end
  end

  def get_properties(node)
    properties = "<ul>"
    node.each_pair do |key, value|
      if key == "avatar_url"
        properties << "<li><img src='#{value}'></li>"
      else
        properties << "<li><b>#{key}:</b> #{value}</li>"
      end
    end
    properties + "</ul>"
  end

  get '/resources/show' do
    content_type :json

    cypher = "START me=node(#{params[:id]}) 
              OPTIONAL MATCH me -[r]- related
              RETURN me, r, related"

    connections = neo.execute_query(cypher)["data"]   
 
    me = connections[0][0]["data"]
    
    relationships = []
    if connections[0][1]
      connections.group_by{|group| group[1]["type"]}.each do |key,values| 
        relationships <<  {:id => key, 
                     :name => key,
                     :values => values.collect{|n| n[2]["data"].merge({:id => node_id(n[2]) }) } }
      end
    end

    relationships = [{"name" => "No Relationships","values" => [{"id" => "#{params[:id]}","name" => "No Relationships "}]}] if relationships.empty?

    @node = {:details_html => "<h2>#{me["name"]}</h2>\n<p class='summary'>\n#{get_properties(me)}</p>\n",
                :data => {:attributes => relationships, 
                          :name => me["name"],
                          :id => params[:id]}
              }

    @node.to_json


  end

  get '/' do
    create_graph
    @neoid = params["neoid"] || 1
    haml :index
  end

end
