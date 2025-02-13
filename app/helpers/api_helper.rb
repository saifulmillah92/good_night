# frozen_string_literal: true

module ApiHelper
  def t(data, **options)
    I18n.t(data, **options)
  end
end
