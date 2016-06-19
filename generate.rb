require 'nokogiri'
require 'net/http'
require 'uri'
require 'sqlite3'
require 'pathname'

DOCUMENT_DIR = Pathname.new("http.docset/Contents/Resources/Documents/")
STATUSES_URI = URI.parse("https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html")
DATABASE_PATH = Pathname.new("http.docset/Contents/Resources/docSet.dsidx")

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

def code_path(code)

end

def fetch_pages
  DOCUMENT_DIR.mkpath unless DOCUMENT_DIR.exist?
  index_file = DOCUMENT_DIR.join('index.html')
  write_page(STATUSES_URI, index_file)
end

def write_page(uri, filename)
  unless File.exists?(filename)
    response = Net::HTTP.get_response(uri)
    File.write(filename, response.body)
  end
end

def create_db
  DATABASE_PATH.unlink if DATABASE_PATH.exist?
  db = SQLite3::Database.new DATABASE_PATH.to_s
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
    db.execute insert_row, [code_short_desc(code), "Type", code_path(code)]
  end
end

fetch_pages
create_db
