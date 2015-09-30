module SparkleMotion
  # A stopwatch class to capture multi-step timing information relatively efficiently.
  class StopWatch
    attr_accessor :results

    def initialize(expected_recordings = 0)
      start           = Time.now
      expected_labels = expected_recordings > 0 ? expected_recordings - 1 : 0
      @timings        = Array.new(expected_recordings)
      @labels         = Array.new(expected_labels)
      @index          = 1
      @timings[0]     = start
    end

    def record!(name)
      @labels[@index - 1] = name
      @timings[@index]    = Time.now
      @index             += 1
    end

    def done!
      elapsed   = timings[1..(@index - 1)]
                  .zip(timings)
                  .map { |(a, b)| ((a.to_f - b.to_f) * 1000).round }
      @results  = Hash[@labels.zip(elapsed)]
    end
  end
end
