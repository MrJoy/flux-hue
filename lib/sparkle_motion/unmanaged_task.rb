module SparkleMotion
  # Wrapper around a frequently-occurring pattern for having a worker thread that's set up early,
  # but not launched until later.
  class UnmanagedTask < Task
    def stop; @thread.kill; end
  end
end
