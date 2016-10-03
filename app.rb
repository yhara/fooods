require 'csv'
require 'fileutils'
require 'date'

require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'
require 'sass'

class Fooods < Sinatra::Base
  configure(:development){ register Sinatra::Reloader }
  enable :sessions

  class Database
    DB = File.expand_path("./db/fooods.csv", __dir__)

    def initialize
      FileUtils.touch(DB) unless File.exist?(DB)
      @rows = CSV.parse(File.read(DB, encoding: "utf-8"))
    end
    attr_reader :rows

    def update_or_insert(name, *args)
      if (a = @rows.find{|x| x[0] == name})
        a[1..-1] = args
      else
        @rows.push([name, *args])
      end
      save
    end

    def delete(name)
      if (a = @rows.find{|x| x[0] == name})
        @rows.delete(a)
      end
      save
    end

    private

    def save
      File.open(DB, "r+") do |f|
        begin
          f.flock(File::LOCK_EX)
          f.rewind; f.truncate(0)
          f.write @rows.map(&:to_csv).join
        ensure
          f.flock(File::LOCK_UN)
        end
      end
    end
  end

  def parse_date(str)
    case str.strip
    when /\A(\d?\d)(\d\d)\z/
      today = Date.today
      m, d = $1.to_i, $2.to_i
      date = Date.new(today.year, m, d)
      date = Date.new(today.year + 1, m, d) if date < today
      date
    when /\A(\d\d)(\d?\d)(\d\d)\z/
      y, m, d = $1.to_i, $2.to_i, $3.to_i
      Date.new(y + 2000, m, d)
    when /\A(\d\d\d\d)(\d?\d)(\d\d)\z/
      y, m, d = $1.to_i, $2.to_i, $3.to_i
      Date.new(y, m, d)
    else
      nil
    end
  rescue ArgumentError
    nil
  end

  get '/screen.css' do
    sass :screen  # renders views/screen.sass as screen.css
  end

  get '/' do
    @db = Database.new
    @rows = @db.rows.sort_by{|name, date, to_by| String(date)}
    @errors = session[:errors]; session[:errors] = nil
    @notices = session[:notices]; session[:notices] = nil
    slim :index  # renders views/index.slim
  end

  post '/save' do
    @db = Database.new
    @errors = []
    @notices = []

    name = String(params["name"])
    @errors << "name is empty" if name.empty?
    date = parse_date(String(params["date"]))
    @errors << "failed to parse date: #{params['date'].inspect}" unless date

    if @errors.any?
      session[:errors] = @errors
    else
      if params["submit_by"] == "Delete"
        @db.delete(name)
        @notices << "Deleted '#{name}'"
      else
        @db.update_or_insert(name, date.to_s, params["to_buy"])
        @notices << "Registered '#{name}' (#{date})"
      end
      session[:notices] = @notices
    end
    redirect back
  end
end
