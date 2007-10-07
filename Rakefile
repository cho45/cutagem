require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'rubyforge'
include FileUtils

AUTHOR = "cho45"
EMAIL = "cho45@lowreal.net"
DESCRIPTION = "More safe eval codes."
RUBYFORGE_PROJECT = "cutagem"
HOMEPATH = "http://#{RUBYFORGE_PROJECT}.rubyforge.org"
BIN_FILES = %w( cutagem )

#VERS = File.read("#{File.dirname(__FILE__)}/bin/cutagem")[/VERSION = "(\d\.\d\.\d)"/, 1]
load "#{File.dirname(__FILE__)}/lib/cutagem.rb"
VERS = CutAGemCommand::VERSION


NAME = "cutagem"
REV = File.read(".svn/entries")[/committed-rev="(d+)"/, 1] rescue nil
CLEAN.include ['**/.*.sw?', '*.gem', '.config']
RDOC_OPTS = ['--title', "#{NAME} documentation",
	"--charset", "utf-8",
	"--opname", "index.html",
	"--line-numbers",
	"--main", "README",
	"--inline-source",
]

desc "Packages up #{NAME} gem."
task :default => [:test]
task :package => [:clean]

Rake::TestTask.new("test") { |t|
	t.libs << "test"
	t.pattern = "test/**/*_test.rb"
	t.verbose = true
}

spec = Gem::Specification.new do |s|
	s.name = NAME
	s.version = VERS
	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	s.extra_rdoc_files = ["README", "ChangeLog"]
	s.rdoc_options += RDOC_OPTS + ['--exclude', '^(examples|extras)/']
	s.summary = DESCRIPTION
	s.description = DESCRIPTION
	s.author = AUTHOR
	s.email = EMAIL
	s.homepage = HOMEPATH
	s.executables = BIN_FILES
	s.rubyforge_project = RUBYFORGE_PROJECT
	s.bindir = "bin"
	s.require_path = "lib"
	s.autorequire = ""
	s.test_files = Dir["test/test_*.rb"]

	#s.add_dependency('activesupport', '>=1.3.1')
	#s.required_ruby_version = '>= 1.8.2'

	s.files = %w(README ChangeLog Rakefile) +
		Dir.glob("{bin,doc,test,lib,templates,generator,extras,website,script}/**/*") +
		Dir.glob("ext/**/*.{h,c,rb}") +
		Dir.glob("examples/**/*.rb") +
		Dir.glob("templates/**/*") +
		Dir.glob("tools/*.rb")

	s.extensions = FileList["ext/**/extconf.rb"].to_a
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true
	p.gem_spec = spec
end

task :install do
	name = "#{NAME}-#{VERS}.gem"
	sh %{rake package}
	sh %{sudo gem install pkg/#{name}}
end

task :uninstall => [:clean] do
	sh %{sudo gem uninstall #{NAME}}
end


Rake::RDocTask.new do |rdoc|
	rdoc.rdoc_dir = 'html'
	rdoc.options += RDOC_OPTS
	rdoc.template = "#{ENV["HOME"]}/coderepos/lang/ruby/rdoc/generators/template/html/resh/resh.rb"
	#rdoc.template = "#{ENV['template']}.rb" if ENV['template']
	if ENV['DOC_FILES']
		rdoc.rdoc_files.include(ENV['DOC_FILES'].split(/,\s*/))
	else
		rdoc.rdoc_files.include('README', 'CHANGELOG')
		rdoc.rdoc_files.include('lib/**/*.rb')
		rdoc.rdoc_files.include('ext/**/*.c')
		rdoc.rdoc_files.include('bin/**/*')
	end
end

desc "Publish to RubyForge"
task :rubyforge => [:rdoc, :package] do
	Rake::RubyForgePublisher.new(RUBYFORGE_PROJECT, 'cho45').upload
end

desc 'Package and upload the release to rubyforge.'
task :release => [:clean, :package] do |t|
	v = ENV["VERSION"] or abort "Must supply VERSION=x.y.z"
	abort "Versions don't match #{v} vs #{VERS}" unless v == VERS
	pkg = "pkg/#{NAME}-#{VERS}"

	rf = RubyForge.new
	puts "Logging in"
	rf.login

	c = rf.userconfig
#	c["release_notes"] = description if description
#	c["release_changes"] = changes if changes
	c["preformatted"] = true

	files = [
		"#{pkg}.tgz",
		"#{pkg}.gem"
	].compact

	puts "Releasing #{NAME} v. #{VERS}"
	rf.add_release RUBYFORGE_PROJECT, NAME, VERS, *files
end
