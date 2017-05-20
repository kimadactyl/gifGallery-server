require 'sinatra'
require 'json'
require 'socket'

# Set server IP dynamically presuming we're on the first 192.168.1.* connection
$SERVER = Socket.ip_address_list.map{ |n| n.ip_address}.select{ |n| n =~ /192\.168\.[0-1]\.[0-9]*/ }.first + ":4567"
$DIR = Dir.pwd
puts "Running on #{$SERVER} at #{$DIR}"

def load_images
  Dir["#{$DIR}/public/*"].select {|x| x =~ /.*\.(gif)/ }
end

# Global variables to track state
$images = load_images
$pointer = 0

def getNextImage
  if $pointer > $images.length - 1
    $pointer = 0
  end
  video = File.basename($images[$pointer])
  extension = File.extname($images[$pointer])
  $pointer += 1
  { pointer: $pointer, video: "http://#{$SERVER}/#{video}", fileType: extension }
end

get '/' do
  '<h1>Gif Gallery Server</h1>'
end

# Alternate method to consider
get '/image' do
  file = getNextImage[:video]
  erb :image, locals: { file: file }
end

get '/image.json' do
  content_type :json
  getNextImage.to_json
end

get '/reload' do
  $images = load_images
  $images.join(", <br>")
end
