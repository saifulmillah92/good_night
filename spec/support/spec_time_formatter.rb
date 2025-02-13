require "rspec/core/formatters/base_formatter"
class SpecTimeFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self, :example_started, :stop

  def initialize(output)
    @output = output
    @times = []
  end

  def example_started(notification)
    current_spec = notification.example.file_path
    if current_spec != @current_spec
      if @current_spec_start_time
        save_current_spec_time
      end
      @current_spec = current_spec
      @current_spec_start_time = Time.now
    end
  end

  def stop(_notification)
    save_current_spec_time
    puts ""
    puts "Total time: #{@times.sum(&:last)}"
    @times.
      sort_by { |_spec, time| -time }.
      each { |spec, time| @output << "#{'%6.2f' % time} seconds #{spec}\n" }
  end

  private

  def save_current_spec_time
    @times << [@current_spec, (Time.now - @current_spec_start_time).to_f]
  end
end
