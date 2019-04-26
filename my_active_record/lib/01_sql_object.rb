require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns unless @columns == nil

    columns = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      "#{self.table_name}"
    SQL

    @columns = columns[0].map! { |column| column.to_sym }

  end

  def self.finalize!
    
    self.columns.each do |column|

      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    objects = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL

    self.parse_all(objects)
  end

  def self.parse_all(results)

    results.inject([]) do |arr, result|
      arr << self.new(result)
    end

  end

  def self.find(id)

    obj = DBConnection.execute(<<-SQL, id)

    SELECT
      *
    FROM
      "#{self.table_name}"
    WHERE
      id = ?
    LIMIT
      1
    SQL
    
    obj.empty? ? nil : self.parse_all(obj)[0]

  end

  def initialize(params = {})

    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end

  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    col_names = self.class.columns.drop(1).map(&:to_sym).join(', ')
    attr_vals = self.attribute_values

    qmarks = []
    attr_vals.length.times { qmarks << '?' }
    joined_qs = qmarks.join(', ')
   
    DBConnection.execute(<<-SQL, *attr_vals)

    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{joined_qs})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.map(&:to_sym)
    col_names.map! { |col| "#{col} = ?"}
    all_cols = col_names.join(', ')

    attr_vals = self.attribute_values
    puts attr_vals

    DBConnection.execute(<<-SQL, *attr_vals)

    UPDATE
      #{self.class.table_name}
    SET
      #{all_cols}
    WHERE
      id = #{attr_vals[0]}

    SQL

  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
