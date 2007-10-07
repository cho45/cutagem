
require "optparse"
require "pathname"
require "fileutils"
require "erb"
require "yaml"

class CutAGemCommand
	VERSION = "0.0.2"

	include FileUtils
	def self.run(argv)
		new(argv.dup).run
	end

	def initialize(argv)
		@argv = argv

		@config = Pathname.new(ENV["HOME"]) + ".cutagem/config.yaml"
		@parser = OptionParser.new do |parser|
			parser.banner = <<-EOB.gsub(/^\t+/, "")
				Usage: #$0 [options] gemname
			EOB

			parser.separator ""
			parser.separator "Options:"

			parser.on("-s", "--select", "Select template interactively.") do |@select|
			end

			parser.on("-d", "--desc", "Describe this gem.") do |@description|
			end

			parser.on("-c", "--config", "Configure user values. Use #{ENV["EDITOR"]}") do |c|
				@config.parent.mkpath
				unless @config.exist?
					@config.open("w") do |f|
						f << <<-EOF.gsub(/^\t+/, "")
						author: "#{ENV['USER']}"
						email:  "#{ENV['USER']}@#{ENV['HOST']}"
						EOF
					end
				end
				exec(ENV["EDITOR"], @config.to_s)
			end

			parser.on("--copy-template NAME", "Copy template to user template dir naming NAME") do |name|
				@select = true
				path = Pathname.new(ENV["HOME"]) + ".cutagem/templates" + name
				if path.exist?
					puts "#{path} is already exists."
					exit 1
				end
				template = select_template()
				cp_r template, path, :verbose => true
				exit
			end

			parser.on("--version", "Show version string `#{VERSION}'") do
				puts VERSION
				exit
			end
		end
	end

	def run
		@parser.order!(@argv)
		unless @argv.first
			puts "gemname must be required."
			exit
		end

		pwd = Pathname.pwd

		author      = ENV['USER']
		email       = "#{ENV['USER']}@#{ENV['HOST']}"
		gemname     = @argv.shift
		gemid       = gemname.gsub("-", "")
		gempath     = gemname.gsub("-", "/")
		gemclass    = gempath.split("/").map {|c|
			c.split(/_/).collect {|i| i.capitalize }.join("")
		}.join("::")
		description = @description

		template = select_template()

		gemdir = pwd + gemname

		if gemdir.exist?
			puts "#{gemdir.basename} is already exists."
			exit
		end

		begin
			config = YAML.load(@config.read)
			author = config["author"] if config["author"]
			email  = config["email"]  if config["email"]
		rescue Errno::ENOENT
		end

		begin
			cp_r template, gemdir, :verbose => true
			Pathname.glob(gemdir + "**/gemname*") do |f|
				f.rename(f.parent + f.basename.to_s.sub(/gemname/, gemname))
			end
			Pathname.glob(gemdir + "**/gempath*") do |f|
				g = f.parent + f.basename.to_s.sub(/gempath/, gempath)
				g.parent.mkpath
				f.rename(g)
			end
			Pathname.glob(gemdir + "**/*") do |f|
				next unless f.file?
				f.open("r+") do |f|
					content = f.read
					f.rewind
					f.puts ERB.new(content).result(binding)
					f.truncate(f.tell)
				end
			end
		rescue
			gemdir.rmtree
			raise
		end

		puts "Done."
		if ENV["EDITOR"]
			puts "Type any key to edit Rakefile."
			gets
			exec(ENV["EDITOR"], gemdir + "Rakefile")
		end
	end

	def select_template
		@templates = Pathname.new(File.dirname(__FILE__)).realpath + '../templates'
		@user_templates = Pathname.new(ENV["HOME"]).realpath + '.cutagem/templates'

		templates = []
		u_templates = []
		if @user_templates.exist?
			Pathname.glob(@user_templates + "*").each do |t|
				t = [".cutagem/templates/#{t.basename}", t]
				if t[1].basename.to_s == "default"
					u_templates.unshift(t)
				else
					u_templates << t
				end
			end
		end
		Pathname.glob(@templates + "*").each do |t|
			t = ["#{t.basename}", t]
			if t[1].basename.to_s == "default"
				templates.unshift(t)
			else
				templates << t
			end
		end
		templates = u_templates + templates

		if @select
			puts "Select template:"
			templates.each_with_index do |item,index|
				puts "% 2d. %s" % [index+1, item.first]
			end
			input = gets.chomp
			case input
			when ""
				template = templates.first
			when /^\d+$/
				template = templates[input.to_i-1]
			else
				template = nil
				puts "Canceled"
				exit
			end
		else
			template = templates.first
		end
		unless template
			puts "Not select template."
			exit
		end
		puts "Using Template: %s" % template
		template[1]
	end
end
