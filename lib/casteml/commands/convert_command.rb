require 'casteml'
require 'casteml/command'
require 'casteml/measurement_category'
class Casteml::Commands::ConvertCommand < Casteml::Command
	def initialize
		super 'convert', '    Convert a {pml, csv, tsv, org, isorg, tex, pdf, dataframe} file to different format.'

		add_option('-f', '--format OUTPUTFORMAT',
						'Specify output format (pml, csv, tsv, org, isorg, tex, pdf, dataframe)') do |v, options|
			options[:output_format] = v.to_sym
		end

		add_option('-n', '--number-format NUMBERFORMAT',
						'Specify number format (%.4g)') do |v, options|
			options[:number_format] = v
		end
		#MeasurementCategory.find_all
		category_names = Casteml::MeasurementCategory.find_all.map{|category| "'" + category.name + "'"}
		add_option('-c', '--category CATEGORY',
						"Specify measurment category (#{category_names.join(', ')})") do |v, options|
			options[:with_category] = v
		end

		# add_option('-d', '--debug', 'Show debug information') do |v|
		# 	options[:debug] = v
		# end
	end

	def usage
		"#{program_name} FILE"
	end
	def arguments
		"    file to be converted (ex; session-all.csv)"
	end

	def description
		<<-EOF
    Convert a {pml, csv, tsv, org, isorg, tex, pdf, dataframe} file to
    different format.

Example:
    $ casteml convert MY_RAT_REEONLY@150106.csv > MY_RAT_REEONLY@150106.pml
    $ ls
    MY_RAT_REEONLY@150106.pml
    $ casteml split MY_RAT_REEONLY@150106.pml

    $ casteml convert -f tex -n %.5g  MY_RAT_REEONLY@150106.pml > MY_RAT_REEONLY@150106.tex
    $ pdflatex MY_RAT_REEONLY@150106.tex

See Also:
    casteml join
    casteml split
    http://dream.misasa.okayama-u.ac.jp

Implementation:
    Copyright (c) 2015 ISEI, Okayama University
    Licensed under the same terms as Ruby

EOF
	end


	def execute
		original_options = options.clone
		options.delete(:build_args)
		args = options.delete(:args)
		raise OptionParser::InvalidArgument.new('specify FILE') if args.empty?
    	path = args.shift

    	string = Casteml.convert_file(path, options)
    	puts string
    	#xml = Casteml::Format::XmlFormat.from_array(data)
	end
end
