require 'sinatra'
require 'json'
require 'net/http'
require 'ri_cal'

set :port, 65010

get '/*' do
  #headers.delete('Cache-Control')
  headers['Access-Contol-Allow-Origin'] = '*'
  headers['Content-Type'] = 'application/json'
  #headers['Cache-Control'] = 'no-cache'
  generate_json
end

def generate_json
  root = Hash.new
  
  generate_non_static(root)
  generate_static(root, 'space/')
  
  root.to_json
end

def generate_static(hash, dir)
  Dir.foreach(dir) do |item|
    next if item == '.' or item == '..' or item[0] == '.'
    
    if File.file?(File.join(dir, item))
      put_value_from_file(hash, File.join(dir, item))
    elsif File.directory?(File.join(dir, item))
      if not hash.has_key?(item)
        put_key(hash, item, Hash.new)
      end
      
      generate_static(hash[item], File.join(dir, item))
    end
  end
end

def generate_non_static(hash)
  # hasi state
  if not hash.has_key?('state')
    hash['state'] = Hash.new
  end
  
  begin
    url = URI.parse('http://www.stats.l3kn.de/api/bool')
    request = Net::HTTP::Get.new(url.path)
    response = Net::HTTP.start(url.host, url.port) { |http|
      http.request(request)
    }
    
    hash['state']['open'] = response.body.strip() == "true"
  rescue
    hash['state']['open'] = false
  end
  
  hash['open'] = hash['state']['open']
  
  # hasi events
 # begin
 #   url = URI.parse('webcal://p06-calendarws.icloud.com/ca/subscribe/1/UBv-TIGJfFoHvGX1Y3IAW_b_RH1l2kaXsN7A1WWNeRCCJBhheEGTp0MqKpds2EJzUaEwhJoFM9iieG9_M3ygAD2RXJWFgSv4Yr6PYPzVUgA')
 #   request = Net::HTTP::Get.new(url.path)
 #   response = Net::HTTP.start(url.host, url.port) { |http|
 #     http.request(request)
 #   }
 #   puts response.body
 #   cals = RiCal.parse_string(response.body.unpack('U*').pack('U*'))
 #   
 #   hash['events'] = []
 #   
 #   cals.each do |cal|
 #     cal.event do |event|
 #       event_hash = Hash.new
 #       
 #       event_hash['name'] = event.description,
 #       event_hash['type'] = "?",
 #       event_hash['timestamp'] = event.dtstart.to_time.to_i,
 #       event_hash['extra'] = "?"
 #       
 #       hash['events'].push(event_hash)
 #     end
 #   end
  #rescue
  #  hash['events'] = []
  #end
end

def put_key(hash, key, value)
  hash[key] = value
end

def put_value_from_file(hash, file)
  begin
    key = File.basename(file, '.*')
    value = IO.readlines(file)
    
    value.map!(&:strip)
    
    if File.extname(file) == '.string' or File.extname(file) == '.stringarray'
    elsif File.extname(file) == '.integer' or File.extname(file) == '.integerarray'
      value.map!(&:to_i)
    elsif File.extname(file) == '.float' or File.extname(file) == '.floatarray'
      value.map!(&:to_f)
    end
    
    is_array = File.extname(file) == '.stringarray' or  \
               File.extname(file) == '.integerarray' or \
               File.extname(file) == '.floatarray'
    
    if value.length == 1 and not is_array
      put_key(hash, key, value[0])
    else
      put_key(hash, key, value)
    end
  rescue
  end
end
