require "bundler/gem_tasks"
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec

# Define a task named `name` that runs all tasks under an identically
# named `namespace`.
def parent_task(name)
  task name do
    ::Rake::Task
      .tasks
      .select { |t| t.name =~ /^#{name}:/ }
      .sort { |a, b| a.name <=> b.name }
      .each(&:execute)
  end
end

desc "Open a Ruby console to Pry."
task :console do
  # rubocop:disable Lint/Debugger
  require "pry"
  require "flux_hue"
  binding.pry
  # rubocop:enable Lint/Debugger
end

namespace :lint do
  desc "Run Rubocop against the codebase."
  task :rubocop do
    require "yaml"
    sh "rubocop --display-cop-names"
  end

  desc "Run bundler-audit against the Gemfile."
  task :'bundler-audit' do
    require "bundler/audit/cli"

    %w(update check).each do |command|
      Bundler::Audit::CLI.start [command]
    end
  end

  have_cloc = `which cloc`.strip != ""
  if have_cloc
    desc "Show LOC metrics for project using cloc."
    task :cloc do
      sh "cloc . --exclude-dir=etc,reference,.bundle,tmp"
    end
  end

  desc "Check for outdated gems."
  task :bundler do
    # Don't error-out if this fails, since we may not be able to update some
    # deps.
    sh "bundle outdated || true"
  end
end

desc "Run all lint checks against the code."
parent_task :lint

task default: [:lint]
