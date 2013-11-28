require 'sinatra'
require 'json'
require 'net/http'

set :port, 65010

get '/' do
  #headers.delete('Cache-Control')
  headers['Access-Contol-Allow-Origin'] = '*'
  headers['Content-Type'] = 'application/json'
  #headers['Cache-Control'] = 'no-cache'
  generate_json
end

get '/set_open/:argument' do
  begin
    open_state = params[:argument]

    if open_state == "true"
      open_one = File.open("space/state/open.boolean", "w")
      open_two = File.open("space/open.boolean", "w")

      open_one.write("true")
      open_two.write("true")

      open_one.close
      open_two.close
    else
      open_one = File.open("space/state/open.boolean", "w")
      open_two = File.open("space/open.boolean", "w")

      open_one.write("false")
      open_two.write("false")

      open_one.close
      open_two.close
    end
  rescue
    # bad.
  end
end

get '/set_temp/:argument' do
  begin
    temp_state = params[:argument]

    temp = File.open("special/temp", "w")
    temp.write(temp_state)
    temp.close
  rescue
    # bad.
  end
end

get '/set_pres/:argument' do
  begin
    pres_state = params[:argument]

    pres = File.open("special/pres", "w")
    pres.write(pres_state)
    pres.close
  rescue
    # bad.
  end
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
  hash['sensors'] = Hash.new
  
  room_temp = Hash.new
  
  room_temp['value'] = File.read("special/temp").to_f
  room_temp['unit'] = '°C'
  room_temp['location'] = 'Inside'
  
  hash['sensors']['temperature'] = [ room_temp ]
  
  room_pres = Hash.new
  
  room_pres['value'] = File.read("special/pres").to_f
  room_pres['unit'] = 'hPa'
  room_pres['location'] = 'Inside'
  
  hash['sensors']['barometer'] = [ room_pres ]
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
    elsif File.extname(file) == '.boolean' or File.extname(file) == '.booleanarray'
      i = 0

      while i < value.length do
        value[i] = value[i] == "true"
        i += 1
      end
    end
    
    is_array = File.extname(file) == '.stringarray' or  \
               File.extname(file) == '.integerarray' or \
               File.extname(file) == '.floatarray' or \
               File.extname(file) == '.booleanarray'
    
    if value.length == 1 and not is_array
      put_key(hash, key, value[0])
    else
      put_key(hash, key, value)
    end
  rescue
  end
end
