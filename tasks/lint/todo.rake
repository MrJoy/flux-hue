namespace :lint do
  desc "Run `todo_lint`."
  task :todo do
    sh "todo_lint"
  end
end
