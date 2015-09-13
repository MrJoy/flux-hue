SOURCE_PATTERNS = [
  "bin/*",
  "examples/**/*",
  "lib/**/*",
  "tasks/**/*",
  "tools/**/*",
]
namespace :lint do
  desc "Run `todo_lint`."
  task :todo do
    sources = FileList[*SOURCE_PATTERNS]
              .reject { |fname| File.directory?(fname) }
    sh "todo_lint --include #{sources.join(' ')}"
  end
end
