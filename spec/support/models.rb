# Included in group definitions to indicate which database adapter the specs in the group should
# run as.
module ModelsGroupHelper
  # Finds the appropriate adapter class for the symbolic adapter name.
  #
  # @param [Symbol] adapter The adapter to look up.
  # @return [Class] The adapter to use for the given adapter.
  # @raise [ArgumentError] If the adapter is unsupported.
  def self.find_adapter(adapter)
    case adapter
    when :sqlite then SqliteAdapter
    else raise ArgumentError, "Unsupported adapter #{adapter}"
    end
  end

  # Declares an example group using the same database adapter.
  def with_database(adapter, &block)
    context "when using a #{adapter} database" do
      around(:each) do |example|
        ModelsGroupHelper.find_adapter(adapter).with_database(&example.method(:run))
      end

      module_eval(&block)
    end
  end
end

RSpec.configure do |config|
  config.extend ModelsGroupHelper
end

# Defines an abstract database adapter for use with specs.
class DatabaseAdapter
  # Runs the provided block with the current database adapter active.
  #
  # @yield The block to execute within the scope of the database.
  def self.with_database
    adapter = new
    yield
  ensure
    adapter.close
  end
  private_class_method :new

  # Initializes the database.
  #
  # @param [Hash] options The connection options to use.
  def initialize(options)
    ActiveRecord::Base.establish_connection(options)
    ActiveRecord::Migration.verbose = false

    define_schema
  end

  # Frees the connection and associated resources.
  def close
    # no-op.
  end

  private

  # Defines the database schema for the adapter.
  def define_schema # rubocop: disable Metrics/MethodLength
    ActiveRecord::Schema.define do
      create_table(:parents) do |t|
        t.timestamps null: false
      end

      create_table(:children) do |t|
        t.timestamps null: false
        t.references :parent
        t.references :other_parent
      end

      create_table(:shapes) do |t|
        t.integer :color, default: 0, null: false
      end
    end
  end
end

class SqliteAdapter < DatabaseAdapter
  def initialize
    super(adapter: 'sqlite3', database: ':memory:')
  end
end

class Parent < ActiveRecord::Base
  has_many :children, -> { order(id: :desc) }
  has_many :other_parents, through: :children
end

class Child < ActiveRecord::Base
  belongs_to :parent
  belongs_to :other_parent, class_name: Parent.name
end

class Shape < ActiveRecord::Base
  enum color: [:red, :green, :blue]
end
