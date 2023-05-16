module Rake
  module DSL
    def task(*args, &block) = Rake::Task.define_task(*args, &block)

    def file(*args, &block) = Rake::FileTask.define_task(*args, &block)

    def cd(path, &block)
      puts "cd #{path}"
      if block
        Dir.chdir(path, &block)
        puts "cd -"
      else
        Dir.chdir(path)
      end
    end

    def sh(command)
      puts command
      system command
    end

    def namespace(name=nil, &block) # :doc:
      Rake.application.in_namespace(name, &block)
    end

    def walk(path)
      return to_enum(:walk, path) unless block_given?
      yield path and return if File.file? path
      Dir.foreach(path) do |entry|
        next if entry == "." or entry ==".."
        entry = File.join([path, entry])
        walk(entry) {|entry| yield entry } if File.directory?(entry)
        yield entry
      end
    end

    def desc(content) = (Rake.application.last_description = content)

    def file_create(*args, &block) = Rake::FileCreationTask.define_task(*args, &block)

    def file_list(path, &block) = walk(path).filter {|e| File.file?(e) and (file(e) if (!block or block.call e))}

    def directory(*args, &block) # :doc:
      dir, _ = *Rake.application.resolve_args(args)
      Rake.each_dir_parent(dir) do |d|
        file_create d do |t|
          Rake.each_dir_parent(t.name).reverse.each { | d | Dir.mkdir(d) unless File.exist?(t.name) }
        end
      end
      file_create(*args, &block)
    end
  end
end

