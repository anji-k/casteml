require "casteml/version"
require 'casteml/exceptions'
require 'tempfile'
#require 'casteml/acquisition'
#require 'casteml/formats/xml_format'
#require 'casteml/formats/csv_format'
#require 'casteml/formats/tex_format'

module Casteml
  autoload(:Acquisition, 'casteml/acquisition.rb')
  module Casteml::Formats
    autoload(:XmlFormat, 'casteml/formats/xml_format.rb')
    autoload(:CsvFormat, 'casteml/formats/csv_format.rb')
    autoload(:TexFormat, 'casteml/formats/tex_format.rb')
  end
  autoload(:Unit, 'casteml/unit.rb')
  autoload(:MeasurementItem, 'casteml/measurement_item.rb')

  # Your code goes here
  #REMOTE_DUMP_DIR = 'remote_dump'
  LIB_DIR = File.dirname File.expand_path(__FILE__)
  GEM_DIR = File.dirname LIB_DIR
  TEMPLATE_DIR = File.join(GEM_DIR,'template')
  CONFIG_DIR = File.join(GEM_DIR,'config')
  ABUNDANCE_UNIT_FILE = File.join(CONFIG_DIR, "alchemist", "abundance.yml")
  def self.convert_file(path, options = {})
    #opts[:type] = opts.delete(:format)
    opts = {}
    opts[:output_format] = options[:output_format]
    unless opts[:output_format]
      opts[:output_format] = Casteml.is_pml?(path) ? :csv : :pml
    end

    if opts[:output_format] == :tex
      opts[:number_format] = options[:number_format] || "%.4g"
    end

    string = encode(decode_file(path), opts)
  end


  def self.encode(data, opts = {})
    type = opts.delete(:output_format) || :pml
    case type
    when :pml
      string = Formats::XmlFormat.to_string(data, opts)
    when :csv
      string = Formats::CsvFormat.to_string(data, opts)
    when :tsv
      string = Formats::CsvFormat.to_string(data, opts.merge(:col_sep => "\t"))
    when :org, :isorg, :isoorg
      string = Formats::CsvFormat.to_string(data, opts.merge(:col_sep => "|")).gsub(/^/,"|").gsub(/\n/,"|\n")
      lines = string.split("\n")
      lines.insert(1,"|-")
      lines.unshift "+TBLNAME: casteml"
      string = lines.join("\n")

    when :tex
      string = Formats::TexFormat.to_string(data, opts)
    when :pdf
      source = Formats::TexFormat.document do |doc|
        doc.puts Formats::TexFormat.to_string(data, opts)
      end
      string = compile_tex(source)
    else
      raise "not implemented"
    end
    string
    # doc = Formats::XmlFormat.from_array(data)
    # fp = StringIO.new
    # Formats::XmlFormat.write(doc, fp)
    # fp.close
    # fp.string
  end

  def self.compile_tex(tex, opts = {})
      fp = Tempfile.open(["casteml-", ".tex"])
      path = fp.path
      fp.puts tex
      fp.close(false)
      basename = File.basename(path, ".tex")
      dirname = File.dirname(path)
      pdfname = basename + ".pdf"
      string = ""
      FileUtils.cd(dirname) {|dir|
        system("pdflatex #{basename}.tex > pdflatex-out")
        string = File.read(pdfname) if File.exist?(pdfname)
      }
      string
  end

  def self.file_type(path)
    ext = File.extname(path)
    ext.sub(/./,"").to_sym
  end

  def self.is_file_type?(path, type)
    file_type(path) == type
  end

  def self.is_pml?(path)
    is_file_type?(path, :pml)
  end

  def self.is_csv?(path)
    is_file_type?(path, :csv)
  end

  def self.is_tsv?(path)
    is_file_type?(path, :tsv)
  end

  def self.is_tex?(path)
    is_file_type?(path, :tex)
  end

  def self.get(id, opts = {})
    require 'medusa_rest_client'
    MedusaRestClient::Record.download_one(:from => MedusaRestClient::Record.casteml_path(id))
  end

  def self.download(id, opts = {})
    pml = get(id, opts)
    fp = Tempfile.open(["downloaded-", ".pml"])
    path = fp.path
    fp.puts pml
    fp.close(false)
    path    
  end

  def self.decode_file(path)
    case File.extname(path)
    when ".pml"
  	 Formats::XmlFormat.decode_file(path)
    when ".csv", ".tsv"
      Formats::CsvFormat.decode_file(path)
    else
      raise "not implemented"
    end
  end


  def self.save_remote(data)
  	case data
  	when Array
  		data.each do |attrib|
  			Acquisition.new(attrib).save_remote
  		end
  	when Hash
  		Acquisition.new(data).save_remote
  	end
  end
end

