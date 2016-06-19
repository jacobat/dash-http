require 'nokogiri'
require 'net/http'
require 'uri'
require 'sqlite3'
require 'pathname'

DOCUMENT_DIR = Pathname.new("http.docset/Contents/Resources/Documents/")
STATUSES_URI = URI.parse("https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html")
DATABASE_PATH = Pathname.new("http.docset/Contents/Resources/docSet.dsidx")

Entry = Struct.new(:name, :path)

def index_file
  File.read('./http.docset/Contents/Resources/Documents/index.html')
end

def codes
  Nokogiri::HTML(index_file).search('h3').map{|node| node_to_data(node) }
end

def node_to_data(node)
  Entry.new(name(node), path(node))
end

def name(node)
  node.children.last.text.strip
end

def path(node)
  "index.html##{node.search('a').first.attributes['id'].value}"
end

def fetch_document
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

def remove_db_if_present
  DATABASE_PATH.unlink if DATABASE_PATH.exist?
end

def create_db
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
    db.execute insert_row, [code.name, "Type", code.path]
  end
end

fetch_document
remove_db_if_present
create_db
