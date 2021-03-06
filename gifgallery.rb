require 'sinatra'
require 'json'
require 'socket'
require 'streamio-ffmpeg'
require 'fastimage'

$DIR = Dir.pwd

# Set server IP dynamically presuming we're on the first 192.168.1.* connection
# $SERVER = Socket.ip_address_list.map{ |n| n.ip_address}.select{ |n| n =~ /192\.168\.[0-1]\.[0-9]*/ }.first + ":4567"
# puts "Running on #{$SERVER} at #{$DIR}"

def load_videos
  files = Dir["#{$DIR}/public/videos/*"].select {|x| x =~ /.*\.(gif|mp4)/ }
  files.reduce([]) do |acc, f|
    ext = File.extname(f)
    if ext == ".mp4"
      mov = FFMPEG::Movie.new(f)
      orientation = mov.width > mov.height ? "landscape" : "portrait"
      acc << { file: File.basename(f), fileType: ext, width: mov.width, height: mov.height, orientation: orientation }
    elsif ext == ".gif"
      width, height = FastImage.size(f)
      orientation = width > height ? "landscape" : "portrait"
      acc << { file: File.basename(f), fileType: ext, width: width, height: height, orientation: orientation }
    end
  end
end

# Global variables to track state
$all_videos = load_videos
$videos = load_videos.dup
$all_landscape_videos = $all_videos.dup.select{ |v| v[:orientation] == "landscape" }
$landscape_videos = $all_landscape_videos.dup
$all_portrait_videos = $all_videos.dup.select{ |v| v[:orientation] == "portrait" }
$portrait_videos = $all_portrait_videos.dup

def getNextVideo(orientation = false)
  data = []
  if orientation == "landscape"
    if $landscape_videos.length == 0
      $landscape_videos = $all_landscape_videos.dup
    end
    data = $landscape_videos.find{ |v| v[:orientation] == "landscape" }
    $landscape_videos.delete(data)
  elsif orientation == "portrait"
    if $portrait_videos.length == 0
      $portrait_videos = $all_portrait_videos.dup
    end
    data = $portrait_videos.find{ |v| v[:orientation] == "portrait" }
    $portrait_videos.delete(data)
  else
    if $videos.length == 0
      $videos = $all_videos.dup
    end
    data = $videos.first
    $videos.delete(data)
  end
  puts data
  {
    video: "/#{data[:file]}",
    fileType: data[:fileType],
    width: data[:width],
    height: data[:height],
    orientation: data[:orientation]
  }
end

get '/' do
  erb :index
end

# Alternate method to consider
get '/image/?:o?' do
  if params[:o]
    orientation = "#{params[:o]}"
    video = getNextVideo(orientation)
    puts "oriented"
  else
    orientation = false
    video = getNextVideo
    puts "not"
  end
  file = video[:video]
  fileType  = video[:fileType]
  erb :image, locals: { file: file, fileType: fileType, orientation: orientation }
end

get '/newimage/?:o?' do
  headers 'Access-Control-Allow-Origin' => '*'
  headers 'Access-Control-Allow-Headers' => 'Authorization,Accepts,Content-Type,X-CSRF-Token,X-Requested-With'
  headers 'Access-Control-Allow-Methods' => 'GET'
  content_type :json
  getNextVideo(params[:o]).to_json
end

get '/reload' do
  $videos = load_videos
  $videos.join(", <br>")
end
