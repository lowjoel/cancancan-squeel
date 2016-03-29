# frozen_string_literal: true
# Implements mapping attributes, values, and comparators for a given model to appropriate
# database equivalents.
#
# This implements:
#  - comparing values against an array: interpreted as any value for ==, none of the values for !=.
#  - mapping foreign keys to IDs
module CanCanCan::Squeel::AttributeMapper
  # Picks the appropriate column, comparator, and value to use in the Squeel expression.
  #
  # This checks for association references: this will use the appropriate column name.
  #
  # Array values are interpreted as alternative choices allowed or disallowed.
  #
  # @param [Class] model_class The model class which the key references.
  # @param [Symbol] key The column being compared.
  # @param [Symbol] comparator The comparator to get the appropriate Squeel comparator for.
  # @param value The value to be comparing against.
  # @return [Array<(Symbol, Symbol, Object)>] A triple containing the column to compare with, the
  #   comparator to use, and the value to compare with.
  def squeel_comparison_for(model_class, key, comparator, value)
    key, value = map_association(model_class, key, value)

    comparator = squeel_comparator_for(comparator, value)
    [key, comparator, value]
  end

  # Picks the table column to compare the value against for the given key.
  #
  # This sets associations to use the proper foreign key column.
  #
  # @param [Class] model_class The model class which the key references.
  # @param [Symbol] key The column being compared.
  # @param value The value to be comparing against.
  # @return [Array<(Symbol, Object)>] A tuple containing the column to compare with and the value
  #   to compare with.
  def map_association(model_class, key, value)
    if (association = model_class.reflect_on_association(key))
      key = association.foreign_key
    end

    [key, value]
  end

  # Maps the given comparator to a comparator appropriate for the given value.
  #
  # Array values are interpreted as alternative choices allowed or disallowed.
  #
  # @param [Symbol] comparator The comparator to get the appropriate Squeel comparator for.
  # @param value The value to be comparing against.
  # @return [Symbol] The comparator for the desired effect, suitable for the given type.
  def squeel_comparator_for(comparator, value)
    if value.is_a?(Array)
      case comparator
      when :== then :>>
      when :!= then :<<
      end
    else
      comparator
    end
  end
end
