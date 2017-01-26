#!/usr/bin/env ruby

class Release

  def initialize(args = [])
    @type = :revision
    @push = false
    @perform = true

    args ||= []

    args.each do |arg|
      opt = arg.to_s.downcase
      if opt == '-major'
        @type = :major
      elsif opt == '-minor'
        @type = :minor
      elsif opt == '-revision'
        @type = :revision
      elsif opt == '-gem'
        @push = true
      elsif opt == '-none'
        @type = :no_change
      elsif opt == '-pretend'
        @perform = false
      elsif Dir.exist?(arg)
        Dir.chdir arg
      else
        Release.help
      end
    end

    @root_path = `git rev-parse --show-toplevel`.to_s.partition("\n")[0].to_s.strip
    raise 'no git repo' unless $?.success?

    app_name = File.basename(@root_path)

    @ver_file =
        if File.exist?("#{@root_path}/version.rb")
          "#{@root_path}/version.rb"
        elsif File.exist?("#{@root_path}/lib/#{app_name}/version.rb")
          "#{@root_path}/lib/#{app_name}/version.rb"
        elsif File.exist?("#{@root_path}/config/version.rb")
          "#{@root_path}/config/version.rb"
        else
          raise 'cannot find version.rb'
        end

  end

  def self.help
    puts <<-EOH
Usage: #{$0} [path] [-major|-minor|-revision] [-gem]
  If a path is specified, it should be the root of a project to release.
  -major     Increments the major version number    (ie - 1.0.0 => 2.0.0)
  -minor     Increments the minor version number    (ie - 1.0.0 => 1.1.0)
  -revision  Increments the revision version number (ie - 1.0.0 => 1.0.1)
  -none      Do not change the version number       (ie - 1.0.0 => 1.0.0)
             The default is to increment the revision.
  -gem       Pushes the gem to rubygems.org.
  -pretend   Do not make any changes.
    EOH
  end

  def run
    orig_m, orig_n, orig_r = get_version
    m,n,r = orig_m, orig_n, orig_r
    if @type == :major
      m += 1
    elsif @type == :minor
      n += 1
    elsif @type == :revision
      r += 1
    end

    # confirm pretend mode if needed.
    puts '== PRETEND ==' unless @perform

    # show version change.
    puts "Version #{orig_m}.#{orig_n}.#{orig_r} => #{m}.#{n}.#{r}"
    set_version m, n, r

    # create tag

    # push to git

    # rake release

  end

  private

  def version_regex
    /^(?<PREFIX>.*module\s+[A-Za-z0-9_]+\s+VERSION\s*=\s*)['"](?<VALUE>[^'"]*)['"](?<POSTFIX>\s+end\s*)$/
  end

  def get_version
    contents = File.read(@ver_file)
    version_regex.match(contents)['VALUE'].to_s.split('.').map{|v| v.to_i}
  end

  def set_version(major, minor, revision)
    new_version = "#{major}.#{minor}.#{revision}"
    if @perform
      contents = File.read(@ver_file)
      data = version_regex.match(contents)
      contents = "#{data['PREFIX']}\"#{new_version.to_s.gsub("\"", "\\\"")}\"#{data['POSTFIX']}"
      File.write(@ver_file, contents)
    end
  end

  def create_tag(major, minor, revision)
    tag = "v#{major}.#{minor}.#{revision}"


  end

end

if $0==__FILE__
  if %w(-h /? /h /help -help --help).include?($1.to_s.downcase)
    Release.help
  else
    Release.new(ARGV).run
  end
end