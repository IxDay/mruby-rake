module Rake
  class Task
    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end

    attr_reader :prerequisites
    attr_accessor :description

    def initialize(name)
      @name = name
      @prerequisites = []
      @actions = []
      @already_invoked = false
      @description = ""
    end

    def invoke
      return if @already_invoked
      return unless needed?
      @prerequisites.each {|p| Rake.application.tasks[p].invoke}
      @actions.each {|b| b.call(self)}
      @already_invoked = true
    end

    def enhance(d, &b)
      @prerequisites += d if d
      @actions << b if b
      self
    end

    def name = @name.to_s
    def reenable = (@already_invoked = false)
    def needed? = true
    def timestamp = Time.now

    class << self
      def [](task_name)
        Rake.application.tasks[task_name.to_s]
      end
    end
  end

  class RuleTask < Task
    def enhance(dependencies, &block)
      @actions << block if block
      dependencies.each do |d|
        Dir.glob("**/*"+d).each do |f|
          name = f.delete_suffix(d) + @name
          Rake::FileTask.define_task(name => [f]) { |t|
            @actions.each { |b| b.call(t) }
          }
          @prerequisites << name
        end
      end
    end
    def invoke = @prerequisites.each {|p| Rake.application.tasks[p].invoke}
    def timestamp = @prerequisites.collect { |p| Rake.application.tasks[p].timestamp }.max
    def needed? =  @prerequisites.any? { |n| Rake.application.tasks[n].needed?  }
  end

  class FileTask < Task
    def needed? = !File.exist?(name) || out_of_date?(timestamp)
    def timestamp = (File::Stat.new(name).mtime if File.exist?(name))
    def out_of_date?(stamp) = @prerequisites.any? { |n|
      Rake.application.tasks[n].needed? || Rake.application.tasks[n].timestamp > stamp
    }
  end

  class FileCreationTask < FileTask
    # Is this file task needed?  Yes if it doesn't exist.
    def needed? = !File.exist?(name)

    # Time stamp for file creation task.  This time stamp is earlier
    # than any other time stamp.
    def timestamp = Rake::EARLY
  end
end
