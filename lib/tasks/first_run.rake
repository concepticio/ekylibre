# -*- coding: utf-8 -*-
module Ekylibre
  LOADERS = [:general_ledger, :entities, :buildings, :products, :animals, :land_parcels, :productions, :analyses, :sales, :deliveries, :interventions]
  LOADERS_OPERATIONS = [:buildings, :products, :land_parcels, :productions, :deliveries, :interventions]

  MAX = -1

  class CountExceeded < StandardError
  end

  class Counter
    attr_reader :count

    def initialize(max = -1)
      @count = 0
      @max = max
    end

    def check_point(increment = 1)
      @count += increment
      print "." if (@count - increment).to_i != @count.to_i
      if @max > 0
        raise CountExceeded.new if @count >= @max
      end
    end
  end

  def self.first_runs
    Rails.root.join("db", "first_runs")
  end

  class Loader
    attr_reader :folder

    def initialize(folder, options = {})
      @folder = folder.to_s
      @folder_path = Ekylibre::first_runs.join(@folder)
      @max = (options[:max] || ENV["max"]).to_i
      @max = MAX if @max.zero?
    end

    def path(*args)
      return @folder_path.join(*args)
    end

    def count(name, options = {}, &block)
      STDOUT.sync = true
      f = Counter.new(@max)
      start = Time.now
      label_size = options[:label_size] || 32
      label = name.to_s.humanize.rjust(label_size)
      if label.size > label_size
        first = ((label_size - 3).to_f / 2).round
        label = label[0..(first-1)] + "..." + label[-(label_size - first - 3)..-1]
        # label = "..." + label[(-label_size + 3)..-1]
      end
      # ActiveRecord::Base.transaction do
      print "[#{@folder.green}] #{label.blue}: "
      begin
        yield(f)
        print " " * (@max - f.count) if @max != MAX and f.count < @max
        print "  "
      rescue CountExceeded => e
        print "! "
      end
      # end
      puts "#{(Time.now - start).round(2).to_s.rjust(6)}s"
    end

  end

end

require 'ostruct'
require 'pathname'

# Build a task with a transaction
def load_data(name, &block)
  task(name => :environment) do
    folder = ENV["folder"]
    folder = "default" if Ekylibre::first_runs.join("default").exist?
    folder ||= "demo"
    ActiveRecord::Base.transaction do
      yield Ekylibre::Loader.new(folder)
    end
  end
end

# # Build a task with a transaction
# def demo(name, &block)
#   task(name => :environment) do
#     ActiveRecord::Base.transaction(&block)
#   end
# end

# namespace :db do
#   task :first_run do
#     Rake::Task["first_run"].invoke
#   end
# end

namespace :first_run do
  for loader in Ekylibre::LOADERS
    require Pathname.new(__FILE__).dirname.join("first_run", loader.to_s).to_s
  end

  desc "Create first_run data for interventions/operations purpose only"
  task :operations => :environment do
    ActiveRecord::Base.transaction do
      for loader in Ekylibre::LOADERS_OPERATIONS
        Rake::Task["first_run:#{loader}"].invoke
      end
    end
  end

end

desc "Create first_run data -- also available " + Ekylibre::LOADERS.collect{|c| "first_run:#{c}"}.join(", ")
task :first_run => :environment do
  ActiveRecord::Base.transaction do
    for loader in Ekylibre::LOADERS
      Rake::Task["first_run:#{loader}"].invoke
    end
  end
end

namespace :first_runs do

  Ekylibre::LOADERS.each_with_index do |loader, index|
    loaders = Ekylibre::LOADERS[index..-1]
    code  = "desc 'Execute #{loaders.to_sentence}'\n"
    code << "task :#{loader} do\n"
    for d in loaders
      code << "  puts ' * Execute first_run:#{d} task'\n"
      code << "  Rake::Task['first_run:#{d}'].invoke\n"
    end
    code << "end"
    eval code
  end

end


desc "Create first_run data independently -- also available " + Ekylibre::LOADERS.collect{|c| "first_run:#{c}"}.join(", ")
task :first_runs => :environment do
  for loader in Ekylibre::LOADERS
    puts " * Execute first_run:#{loader} task"
    Rake::Task["first_run:#{loader}"].invoke
  end
end


