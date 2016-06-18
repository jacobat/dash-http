require 'nokogiri'
require 'net/http'
require 'uri'
require 'sqlite3'

def index_file
  File.read('./http.docset/Contents/Resources/Documents/index.html')
end

def codes
  Nokogiri::HTML(index_file).search('.codes li a').map{|node|
    node.search('span').text
  }
end

def code_short_desc(code)
	Nokogiri::HTML(index_file).search('.codes li a').detect{|node|
    node.search('span').text == code.to_s
  }.text
end

def fetch_pages
  index_uri = URI.parse("https://httpstatuses.com/")
  index_file = "http.docset/Contents/Resources/Documents/index.html"
  write_page(index_uri, index_file)
  codes.each do |code|
    uri = URI.parse("https://httpstatuses.com/#{code}")
    filename = "http.docset/Contents/Resources/Documents/#{code}.html"
    write_page(uri, filename)
  end
end

def write_page(uri, filename)
  unless File.exists?(filename)
    response = Net::HTTP.get_response(uri)
    File.write(filename, response.body)
  end
end

def createdb
  if File.exists?("http.docset/Contents/Resources/docSet.dsidx")
    File.unlink("http.docset/Contents/Resources/docSet.dsidx")
  end
	db = SQLite3::Database.new "http.docset/Contents/Resources/docSet.dsidx"
	db.execute <<-SQL
CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);
	SQL
	db.execute <<-SQL
CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
	SQL
	insert_row = <<-SQL
INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?);
	SQL
	codes.each do |code|
		db.execute insert_row, [code_short_desc(code), "Type", "#{code}.html"]
	end
end

fetch_pages
createdb
