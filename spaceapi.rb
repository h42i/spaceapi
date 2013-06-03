require 'sinatra'
require 'json'
require 'net/http'

get '/*' do
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
