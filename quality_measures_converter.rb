require 'pry'
require 'json'

class QualityMeasuresConverter
  def parse_filename(filepath)
    filepath.split('/').last.split('.').first
  end

  # This method loads all the schema files into memory, and loops through them
  # creating a hash for each measure's schema
  def schemas
    @schema ||= Dir['schemas/*'].reduce({}) do |schemas, file|
      filename = parse_filename(file)
      schemas[filename] = File.read(file).split("\n").map do |row|
        values = row.split(',')
        {
          name: values[0],
          length: values[1],
          type: values[2]
        }
      end

      schemas
    end
  end

  # This method loads all the data files into memory, and loops through them
  # parsing them according to their corresponding schema
  def data
    @data ||= Dir['data/*'].reduce({}) do |data, file|
      raw_data = File.read(file)
      filename = parse_filename(file)
      schema = schemas[filename]

      data[filename] = raw_data.split("\n").map do |row|
        schema.reduce({}) do |object, column|
          # slice from the beginning of the row the relevant number of
          # characters based on the column's attribute length
          raw_value = row.slice!(0, column[:length].to_i)

          parsed_value = parse_attribute(raw_value, column[:type])
          object[column[:name]] = parsed_value
          object
        end
      end
    end
  end

  # Takes a value and a data type and casts the value according to the type
  def parse_attribute(value, type)
    case type
    when 'INTEGER'
      value.to_i
    when 'BOOLEAN'
      value.to_i == 1
    when 'TEXT'
      value.strip
    else
      raise 'Invalid data type'
    end
  end

  # Taking the parsed data object, this method writes it to a json file `results.json`
  def output_json_file
    File.write('results.json', { data: data }.to_json)
  end
end



converter = QualityMeasuresConverter.new
converter.output_json_file
p converter.data
