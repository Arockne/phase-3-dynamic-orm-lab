require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "PRAGMA table_info(#{table_name})"
    columns = DB[:conn].execute(sql)
    table_names = columns.map { |col| col["name"] }
    table_names.compact
  end

  def initialize(options = {})
    options.each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == 'id' }.join(', ')
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col|
      values << "'#{send(col)}'" unless send(col).nil?
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid()")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE name = ?
    SQL
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attr)
    value = attr.values.first
    formatted_value = value.class == Integer ? value : "'#{value}'"
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{attr.keys.first} = #{formatted_value}")
    # condition = []
    # attr.each { |key, value| condition << "#{key} = '#{value}'"}
    # condition = condition.join(", ")
    # DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{condition}")
  end
end