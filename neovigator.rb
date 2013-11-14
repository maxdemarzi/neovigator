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
      @neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    end
  end
  
  def hashify(results)
    results["data"].map {|row| Hash[*results["columns"].zip(row).flatten] }
  end

  def create_graph
    return if neo.execute_query("start n = node(*) return count(n)")["data"].first.first > 1

    guys = %w[Adrian Ben Carl Darrel Elliott Felix Gary Harley Ian Jason Keith Lance Marco Ned Otto Pablo Quentin Rocky Sheldon Ted Ulysses Val Warren Young Zack]
    girls = %w[Alesha Bethany Carrie Darcey Emely Frida Gabrielle Helene Isabelle Jacqualine Katheryn Lora Megan Nathalie Olivia Patricia Rachael Shanon Tiffany Vannessa Wendie Xuan Yolonda Zofia]
    cities = %w[Austin Baltimore Charlotte Chicago Dallas Detroit Miami Oakland Philadelphia Wichita]
    attributes = %w[Able Accepting Adventurous Aggressive Ambitious Annoying Arrogant Articulate Athletic Awkward Boastful Bold Bossy Brave Bright Busy Calm Careful Careless Caring Cautious Cheerful Clever Clumsy Compassionate Complex Conceited Confident Considerate Cooperative Courageous Creative Curious Dainty Daring Dark Defiant Demanding Determined Devout Disagreeable Disgruntled Dreamer Eager Efficient Embarrassed Energetic Excited Expert Fair Faithful Fancy Fighter Forgiving Free Friendly Friendly Frustrated Fun-loving Funny Generous Gentle Giving Gorgeous Gracious Grouchy Handsome Happy Hard-working Helpful Honest Hopeful                            Humble Humorous Imaginative Impulsive Independent Intelligent Inventive Jealous Joyful Judgmental Keen Kind Knowledgeable Lazy Leader Light Light-hearted Likeable Lively Lovable Loving Loyal Manipulative Materialistic Mature Melancholy Merry Messy Mischievous Naïve Neat Nervous Noisy Obnoxious Opinionated Organized Outgoing Passive Patient Patriotic Perfectionist Personable Pitiful Plain Pleasant Pleasing Poor Popular Pretty Prim Proper Proud Questioning Quiet Radical Realistic Rebellious Reflective Relaxed Reliable Religious Reserved Respectful Responsible Reverent Rich Rigid Rude Sad Sarcastic Self-confident Self-conscious Selfish Sensible Sensitive Serious Short Shy Silly Simple Simple-minded Smart Stable Strong Stubborn Studious Successful Tall Tantalizing Tender Tense Thoughtful Thrilling Timid Tireless Tolerant Tough Tricky Trusting Ugly Understanding Unhappy Unique Unlucky Unselfish Vain Warm Wild Willing Wise Witty Zany]
  
    cypher = "CREATE (n {nodes}) RETURN  ID(n) AS id, n.name AS name"

    nodes = []
    guys.each { |n| nodes <<  {"name" => n, "gender" => "male"} }
    girls.each { |n| nodes << {"name" => n, "gender" => "female"} }
    users = hashify(neo.execute_query(cypher, {:nodes => nodes}))

    nodes = []
    cities.each { |n| nodes << {"name" => n} }
    cities = hashify(neo.execute_query(cypher, {:nodes => nodes}))
  
    nodes = []  
    attributes.each { |n| nodes << {"name" => n} }
    attributes = hashify(neo.execute_query(cypher, {:nodes => nodes}))
  
    commands = []
    users.each do |user| 
      commands << [:add_node_to_index, "users_index", "name", user["name"], user["id"]]
    end  
    results = neo.batch *commands

    commands = []
    users.each do |user| 
      commands << [:create_relationship, "lives_in", user["id"], cities.sample["id"], nil]    
    end  
    neo.batch *commands

    users.each do |user| 
      commands = []
      users.sample(3 + rand(10)).each do |att|
        commands << [:create_relationship, "friends", user["id"], att["id"], nil] unless (att["id"] == user["id"])   
      end
      neo.batch *commands
    end  

    users.each do |user| 
      commands = []
      attributes.sample(10 + rand(10)).each do |att|
        commands << [:create_relationship, "has", user["id"], att["id"], nil]    
      end
      neo.batch *commands
    end  

    users.each do |user| 
      commands = []
      attributes.sample(10 + rand(10)).each do |att|
        commands << [:create_relationship, "wants", user["id"], att["id"], nil]    
      end
      neo.batch *commands
    end 
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
    neo = Neography::Rest.new    

    cypher = "START me=node(#{params[:id]}) 
              MATCH me -[r?]- related
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

    relationships = [{"name" => "No Relationships","name" => "No Relationships","values" => [{"id" => "#{params[:id]}","name" => "No Relationships "}]}] if relationships.empty?

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
