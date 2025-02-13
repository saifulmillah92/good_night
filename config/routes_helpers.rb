# frozen_string_literal: true

module RoutesHelpers
  def json
    { defaults: { format: :json } }
  end

  def override(*args)
    { constraints: OverrideParams.new(*args) }
  end

  def query_override(params)
    { constraints: OverrideParams.new(query: params) }
  end

  def body_override(params)
    { constraints: OverrideParams.new(body: params) }
  end

  def api(version, options, &block)
    version_options = {
      path: version,
      defaults: { __version: version, format: :json },
    }
    version_options.merge!(options.except(:defaults))
    version_options[:defaults].merge!(options[:defaults] || {})

    scope(version_options, &block)
  end

  def has_param(keyval)
    { constraints: ->(req) { keyval.all? { |k, v| req.parameters[k] == v } } }
  end

  def allow_dot(param)
    { constraints: { param => %r{[^/]+} } }
  end

  def rack_json(status = :ok, json)
    status = Rack::Utils.status_code(status)
    return [status, {}, []] unless json

    string = json.to_json
    [
      status,
      {
        'Content-Type' => 'application/json',
        'Content-Length' => string.bytesize.to_s,
      },
      [string],
    ]
  end
end

class OverrideParams
  def initialize(query: {}, body: {})
    @query = query
    @body = body
  end

  def matches?(request)
    query = fill_variables(@query, request.params)
    query.each do |key, value|
      request.query_parameters[key] = value
    end

    body = fill_variables(@body, request.params)
    body.each do |key, value|
      request.request_parameters[key] = value
    end

    # ensure params[val] returns the override
    body.merge(query).each do |key, value|
      request.params[key] = value
    end

    true
  end

  def fill_variables(params, source)
    params.transform_values do |val|
      if val.is_a?(Symbol)
        source[val.to_s]
      else
        val
      end
    end
  end
end
