# frozen_string_literal: true

require_relative "json_matcher"

module HelpersForRequests
  def get_json(url, body = {}, headers = {})
    get(
      url,
      params: body,
      headers: headers.reverse_merge(default_headers),
    )
  end

  def post_json(url, body = {}, headers = {})
    post(
      url,
      params: body.to_json,
      headers: headers.reverse_merge(default_headers),
    )
  end

  def put_json(url, body = {}, headers = {})
    put(
      url,
      params: body.to_json,
      headers: headers.reverse_merge(default_headers),
    )
  end

  def patch_json(url, body = {}, headers = {})
    patch(
      url,
      params: body.to_json,
      headers: headers.reverse_merge(default_headers),
    )
  end

  def delete_json(url, body = {}, headers = {})
    delete(
      url,
      params: body.to_json,
      headers: headers.reverse_merge(default_headers),
    )
  end

  def as_user(user, **params)
    bearer(access_token(user, **params))
  end

  def bearer(token)
    { Authorization: "Bearer #{token}" }
  end

  def expect_response(status, json = nil)
    begin
      expect(response).to have_http_status(status)
    rescue RSpec::Expectations::ExpectationNotMetError => e
      e.message << "\n#{JSON.pretty_generate(response_body)}"
      raise e
    end
    expect(response_body).to be_json_type(json) if json
  end

  def expect_error_response(status = nil, message = nil, details: nil)
    status ||= Integer
    message ||= String
    code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status
    error_format = { error: { code: code, message: message } }

    begin
      if status == Integer
        error_message = "expected: 4xx, got: #{response.status}"
        expect(response.client_error?).to eq(true), error_message
      else
        expect(response).to have_http_status(status)
      end
    rescue RSpec::Expectations::ExpectationNotMetError => e
      e.message << "\n#{JSON.pretty_generate(response_body)}"
      raise e
    end

    expect(response_body).to be_json_type(error_format)

    error_message = response_body.fetch(:error).fetch(:message)
    return unless error_message.is_a?(String)

    expect(error_message).not_to match(/translation missing:/), error_message
  end

  def response_body
    JSON.parse(response.body, symbolize_names: true)
  end

  def default_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  module ClassMethods
    def info(text)
      metadata[:info] = text
    end

    def doc_root(path)
      metadata[:doc_root] = path
    end

    def doc_api(method, path)
      metadata[method.to_s.upcase.to_sym] = path
    end
  end
end

RSpec.configure do |config|
  config.include HelpersForRequests, type: :request
  config.extend HelpersForRequests::ClassMethods, type: :request

  if ENV["DOC"]
    config.before(:all, type: :request) do |_ex|
      @doc = SpecDocumenter::Document.new
    end

    config.after(:each, type: :request) do |ex|
      next unless ex.metadata[:doc]

      @doc.file ||= ex.metadata[:file_path].parameterize.underscore
      @doc.document(ex.metadata, request: request, response: response)
    end

    config.after(:all, type: :request) do |_ex|
      next if @doc.blank?

      path = Rails.root.join("docs/#{@doc.file}.md")

      File.open(path, "w") do |f|
        SpecDocumenter::Writer.new(f).write(@doc)
      end
    end

    config.after(:suite) do |_ex|
      doc_path = Rails.root.join("apiary.apib")
      manifest = Rails.root.join("docs/apiary.manifest")

      File.open(doc_path, "w") do |doc|
        File.readlines(manifest).each do |path|
          path = path.sub("\n", "").presence
          path || next
          doc.puts File.read(Rails.root.join(path))
        end
      end
    end
  end
end
