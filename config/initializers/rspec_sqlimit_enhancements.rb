# frozen_string_literal: true

if defined? RSpec::SQLimit
  class RSpec::SQLimit::Counter
    module BacktraceReducer
      def self.call(backtrace)
        backtrace = backtrace.map { |line| line.sub(Rails.root.to_s, ".") }
        backtrace = backtrace.grep %r{\Wapp/}
        backtrace -= backtrace.grep(/json_error_middleware\.rb.*call/)
        backtrace -= backtrace.grep(/access_token_middleware\.rb.*call/)
        backtrace -= backtrace.grep(/application_controller\.rb.*catch/)
        backtrace -= backtrace.grep(/organization\.rb.*within/)
        backtrace -= backtrace.grep(/current\.rb.*using/)
        backtrace
      end
    end

    def initialize(matcher, options, block)
      @queries = []
      @matcher = matcher
      @options = options
      @block   = block
      @mutex   = Mutex.new
    end

    private

    def callback
      @callback ||= lambda do |_name, start, finish, _message_id, values|
        return if ["CACHE", "SCHEMA"].include? values[:name]
        return if cached_query?(values) && !@options[:include_cached]

        queries << {
          backtrace: BacktraceReducer.call(caller),
          sql: values[:sql],
          duration: (finish - start) * 1_000,
          binds: get_bind_values(values),
        }
      end
    end

    def get_bind_values(values)
      get_values(values[:type_casted_binds]) || type_cast(values[:binds])
    end

    def get_values(type_casted_binds)
      return type_casted_binds.call if type_casted_binds.respond_to?(:call)

      type_casted_binds
    end
  end

  class RSpec::SQLimit::Reporter
    def query_trace_guide_message(context)
      if ENV["QUERY_TRACE"]
        tell_to_see_the_log_file
      else
        describe_how_to_do_query_tracing(context)
      end
    end

    def tell_to_see_the_log_file
      "Check the content of #{log_path} to determine the source of N+1 queries\n  "
    end

    def describe_how_to_do_query_tracing(context)
      <<-MESSAGE.gsub(/ +\|/, "")
        |To debug, run the script below then check the content of #{log_path}:
        |
        |CLEAR_LOGS=1 QUERY_TRACE=1 LOCAL=1 rspec #{spec_path(context)}\n#{"  "}
      MESSAGE
    end

    def log_path
      log_path = Rails.application.paths["log"].first
      Pathname.new(log_path).relative_path_from(Rails.root)
    end

    def spec_path(context)
      context.inspect.match(%r{(\./.*\))}).to_a[0][0..-2]
    end

    def lines
      lines = @queries.map.with_index { |*args| line(*args) }
      lines << ""
      lines << "Suspected N+1 queries:"
      lines << ""
      lines.concat(suspect_lines)
    end

    def suspects
      @suspects ||= gather_suspects
    end

    def gather_suspects
      groups = @queries.each_with_index.group_by do |query, _i|
        [normalized_sql(query[:sql]), query[:backtrace]]
      end

      groups.each_with_object([]) do |(_, queries_with_index), result|
        result << store_indexes(queries_with_index) if queries_with_index.size > 1
      end
    end

    def store_indexes(queries_with_index)
      query, _index = queries_with_index.first
      query.merge(indexes: queries_with_index.map(&:last))
    end

    def suspect_lines
      return ["-"] if suspects.empty?

      indentation = " " * (numeric_size + 4)
      build_suspect_lines(indentation)
    end

    def build_suspect_lines(indentation = "")
      suspects.each_with_object([]) do |query, result|
        result << "Query no. #{query[:indexes].map { |x| x + 1 }.join(", ")}:"
        result << line(query, nil)
        result.concat(query[:backtrace].map { |line| "#{indentation} #{line}" })
        result << ""
      end
    end

    def line(query, index = nil)
      sql = truncated_sql(query[:sql])
      prefix = matcher && query[:sql] =~ matcher ? "->" : "  "
      binds = truncated_binds(query[:binds].to_a)

      "#{prefix} #{number(index)} #{sql}#{binds} (#{query[:duration].round(3)} ms)"
    end

    def normalized_sql(sql)
      sql = sql.dup
      sql.gsub!(/\d+/, "0") # convert all numbers to zero
      sql.gsub!(/\$0/, "0") # convert all bind vars to zero
      sql.gsub!(/\([0, ]+\)/, "()") # convert bind lists ($1, $2...) to empty lists
      sql.gsub!(/= ?0/i, "IN ()") # convert equality to IN ()
      sql
    end

    def truncated_sql(sql)
      plain_select = /SELECT (("?[a-z_]+"?\.?){1,2}"?[a-z_*]+"?( AS \w+)?,? )+/
      sql = sql.dup
      sql.gsub!(plain_select, "SELECT ... ") # truncate list of selected columns
      sql.gsub!(/\$9, \$10, [^)]+\)/, "$9, ...)") # truncate long IN ( ) statement
      sql
    end

    def truncated_binds(binds)
      binds = binds[0, 9] << "..." if binds.size > 10
      binds.any? ? "; #{binds} " : ""
    end

    def number(index)
      index ? format("%0#{numeric_size}d)", index + 1) : " " * (numeric_size + 1)
    end

    def numeric_size
      @numeric_size ||= @count.to_s.size
    end
  end

  RSpec::Matchers.define :exceed_query_limit do |expected, **options|
    chain(:with) { |matcher| @matcher = matcher }

    match do |block|
      @matcher ||= /^(?!.*SELECT nspname FROM pg_namespace).*$/ # enhancement
      @counter ||= RSpec::SQLimit::Counter[@matcher, options, block]
      ENV["LIST_QUERIES"] ? false : @counter.count > expected # enhancement
    end

    match_when_negated do |block|
      @counter ||= RSpec::SQLimit::Counter[@matcher, options, block]
      ENV["LIST_QUERIES"] ? false : @counter.count <= expected # enhancement
    end

    failure_message { |_| message(expected) }

    failure_message_when_negated { |_| message(expected, negation: true) }

    supports_block_expectations

    def message(expected, negation: false)
      reporter    = RSpec::SQLimit::Reporter.new(@counter)
      condition   = negation ? "maximum" : "more than"
      restriction = " that match #{reporter.matcher}" if reporter.matcher

      <<-MESSAGE.gsub(/ +\|/, "")
        |Expected to run #{condition} #{expected} queries#{restriction}
        |#{reporter.call}
        |#{reporter.query_trace_guide_message(@matcher_execution_context)}
      MESSAGE
    end
  end
end
