# frozen_string_literal: true

# RubocopDiff
module RubocopDiff
  DIR = File.expand_path("..", __dir__)
  GIT_DIFF = 'git --no-pager diff \
                  --diff-filter=ACMR \
                  -U0 \
                  "$GITHUB_BASE_REF...$GITHUB_HEAD_REF"'

  module_function

  # Runner
  module Runner
    def file_offenses(file)
      @__ranges ||= RubocopDiff.git_diff_ranges
      ranges = @__ranges[file].to_a
      super.select do |offense|
        ranges.any? do |range|
          range.cover?(offense.first_line) || range.cover?(offense.last_line)
        end
      end
    end
  end

  # Returns hash of file name and line number ranges
  def git_diff_ranges
    lines = `#{GIT_DIFF}`.split("\n")
    current = nil

    lines.each_with_object({}) do |line, hash|
      if (file = target_file(line))
        current = hash[file] = []
      elsif (range = position_range(line))
        current << range
      end
    end
  end

  def target_file(line)
    File.join(DIR, Regexp.last_match(1)) if line =~ %r{\+\+\+ b/(.+)}
  end

  def position_range(line)
    return unless line =~ /@@ -\d+,?.* \+(\d+),?(\d+)?/

    line_start = Regexp.last_match(1).to_i
    lines = Regexp.last_match(2).to_i
    (line_start..(line_start + lines))
  end
end

RuboCop::Runner.prepend(RubocopDiff::Runner)
