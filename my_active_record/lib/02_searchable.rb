require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

    where_line = params.keys.map { |key| "#{key} = ?" }
    where_line = where_line.join(' AND ')
    values = params.values

    objs = DBConnection.execute(<<-SQL, *values)

      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}

    SQL

    objs.map { |obj| self.new(obj)} 

  end
end

class SQLObject
  extend Searchable
end
