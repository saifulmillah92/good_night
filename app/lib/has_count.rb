# frozen_string_literal: true

module HasCount
  def has_count(name, additional_scope = nil, association:, column: "*", foreign_key: nil, class_name: nil)
    additional_scope ||= -> { all }
    foreign_key      ||= "#{table_name.tableize.singularize}_id"
    class_name       ||= reflect_on_association(association).class_name

    count_column = "COUNT(#{column})"
    scope = -> { select(foreign_key, count_column).group(foreign_key).instance_exec(&additional_scope) }

    has_one name, scope, class_name: class_name.to_s, foreign_key: foreign_key

    define_method name do
      if association(association).loaded?
        association(association).size
      else
        association(name).reader&.count.to_i
      end
    end
  end
end
