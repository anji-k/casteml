require 'casteml/command'
require 'casteml'
require 'casteml/formats/xml_format'
class Casteml::Commands::DownloadCommand < Casteml::Command
	def initialize
		super 'download', '    Download pmlfile from Medusa'

		add_option('-f', '--format OUTFORMAT',
						'Output format (pml, csv, tsv, org, isorg, tex, pdf, dataframe)') do |v, options|
			options[:output_format] = v.to_sym
		end

		add_option('-r', '--recursive', 
						'Analyses with descendants of a stone') do |v|
			options[:recursive] = :self_and_descendants
		end

		add_option('-R', '--Recursive', 
						'Analyses with a whole family of a stone') do |v|
			options[:recursive] = :families
		end

		add_option('-n', '--number-format NUMFORMAT',
						'Number format (%.4g)') do |v, options|
			options[:number_format] = v
		end		
	end

	def usage
		"#{program_name} [options] id0 [id1 ...]"
	end

	def description
    <<-EOS
    Download pmlfile from Medusa.  Specify ID as argument.  This
    accepts both stone-ID and analysis-ID.  For stone-ID, recursive
    download is available.  The default output is toward to the
    standard output.  Redirect to certain file.

    This command accept more than one ID.  Note that you can also
    obtain a multi-pmlfile for a whole family.  If you need a
    multi-pmlfile, (1) download similatentously or (2) seperately then
    join them by a command `casteml join'.

    You may want to plot the multi-pmlfile by a command `casteml
    plot'.

Example:
    $ casteml download 20130528105235-594267
    ...
    $ casteml download -r 20130528105235-594267 > download.pml
    $ casteml convert download.pml -f csv > data-from-casteml.csv
    ...
    $ casteml download 20110205103129-336-399 20110203174950-308-353 > c.pml
    ...
    $ casteml download 20110205103129-336-399 > a.pml
    $ casteml download 20110203174950-308-353 > b.pml
    $ casteml join a.pml b.pml > c.pml
    ...
    $ casteml plot c.pml

See Also:
    casteml convert
    casteml join
    casteml plot
    http://dream.misasa.okayama-u.ac.jp

Implementation:
    Orochi, version 9
    Copyright (C) 2015 Okayama University
    License GPLv3+: GNU GPL version 3 or later

EOS
	end

	def execute
		original_options = options.clone
		options.delete(:build_args)
		args = options.delete(:args)
		raise OptionParser::InvalidArgument.new('specify stone-ID or analysis-ID') if args.empty?
		#id = args.shift
		options_download = {}
		options_download[:recursive] = options[:recursive] if options[:recursive]
        paths = []
        while(id = args.shift) do 
    	  paths << Casteml.download(id, options_download)
        end
        path = Casteml::Formats::XmlFormat.join_files(paths)

        string = File.read(path)
    	if options[:output_format]
	    	string = Casteml.encode(Casteml::Formats::XmlFormat.decode_string(string), options)
    	end
    	say string
	end

end
