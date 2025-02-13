# frozen_string_literal: true

RSpec::Matchers.define :be_json_type do |expected|
  match do |actual|
    case expected
    when Array then expect(actual).to be_array_type(expected, [])
    when Hash then expect(actual).to be_hash_type(expected, [])
    end
  rescue RSpec::Expectations::ExpectationNotMetError => e
    @message = e.message
    @message += "\n#{JSON.pretty_generate(actual)}"
    false
  end

  failure_message do
    @message
  end
end

RSpec::Matchers.define :be_array_type do |expected, path|
  match do |actual|
    expect(actual).to be_a(Array)
    expected.empty? && (return expect(actual).to eq expected)
    actual.empty? && (return expect(actual).to eq expected)

    expected = actual.length.times.map { expected[0] } if expected.length == 1

    expected.each_with_index.all? do |spec_el, i|
      @spec_el = spec_el
      @value_el = value_el = actual[i]
      @el_path = el_path = path + ["[#{i}]"]
      case spec_el
      when Array then expect(value_el).to be_array_type(spec_el, el_path)
      when Hash then expect(value_el).to be_hash_type(spec_el, el_path)
      when Module then value_el.is_a?(spec_el)
      when RSpec::Matchers::Composable then expect(value_el).to spec_el
      else value_el == spec_el
      end
    end
  rescue RSpec::Expectations::ExpectationNotMetError => e
    @message = e.message
    false
  end

  failure_message do
    @value_el = "\"#{@value_el}\"" if @value_el.is_a?(String)
    @value_el = 'nil' if @value_el.nil?
    @message || <<-MSG.squish
      json#{@el_path.join('')} was #{@value_el}, expected to be #{@spec_el}
    MSG
  end
end

RSpec::Matchers.define :be_hash_type do |expected, path|
  match do |actual|
    expect(actual).to be_a(Hash)
    expected.empty? && (return expect(actual).to eq expected)
    actual.empty? && (return expect(actual).to eq expected)

    expected.all? do |key, spec_el|
      @spec_el = spec_el
      @value_el = value_el = actual[key]
      @el_path = el_path = path + ["[:#{key}]"]
      case spec_el
      when Array then expect(value_el).to be_array_type(spec_el, el_path)
      when Hash then expect(value_el).to be_hash_type(spec_el, el_path)
      when Module then value_el.is_a?(spec_el)
      when RSpec::Matchers::Composable then expect(value_el).to spec_el
      else value_el == spec_el
      end
    end
  rescue RSpec::Expectations::ExpectationNotMetError => e
    @message = e.message
    false
  end

  failure_message do |_actual|
    @value_el = "\"#{@value_el}\"" if @value_el.is_a?(String)
    @value_el = 'nil' if @value_el.nil?
    @message || <<-MSG.squish
      json#{@el_path.join('')} was #{@value_el}, expected to be #{@spec_el}
    MSG
  end
end

module MatcherAliases
  def is_hash(*args)
    be_hash_type(*args)
  end

  def is_array(*args)
    be_array_type(*args)
  end
end

RSpec.configure do |config|
  config.include MatcherAliases
end
