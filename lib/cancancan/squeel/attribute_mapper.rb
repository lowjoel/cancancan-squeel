# frozen_string_literal: true
# Implements mapping attributes, values, and comparators for a given model to appropriate
# database equivalents.
#
# This implements:
#  - comparing values against an array: interpreted as any value for ==, none of the values for !=.
#  - mapping foreign keys to IDs
module CanCanCan::Squeel::AttributeMapper
  module_function

  # Picks the appropriate column, comparator, and value to use in the Squeel expression.
  #
  # This checks for association references: this will use the appropriate column name.
  # Array values are interpreted as alternative choices allowed or disallowed.
  # Ranges are converted to appropriate comparator pairs.
  #
  # The return value is a tuple:
  #
  #  - The first element is a combinator to be used on the comparisons.
  #  - The second element is an array of comparisons: each comparison is a tuple of
  #    (key, comparator, value)
  #
  # The appropriate expression is the combination of all the comparisons, using the combinator
  # returned.
  #
  # @example Attribute Ranges
  #   squeel_comparison_for(User, :id, :==, 1..5) #=> [:&, [[:id, :>=, 1], [:id, :<=, 5]]]
  # @example Association Objects
  #   squeel_comparison_for(Post, :comment, :==, comment) #=> [:&, [[:comment_id, :==, 1]]]
  #
  # @param [Class] model_class The model class which the key references.
  # @param [Symbol] key The column being compared.
  # @param [Symbol] comparator The comparator to get the appropriate Squeel comparator for.
  # @param value The value to be comparing against.
  # @return [Array<(Symbol, Array<(Symbol, Symbol, Object)>)>] A tuple containing the combinator for
  #   the comparisons, and a sequence of comparisons.
  def squeel_comparison_for(model_class, key, comparator, value)
    key, value = map_association(model_class, key, value)

    combinator, comparisons = squeel_comparator_for(comparator, value)
    [combinator, comparisons.map { |comp| comp.unshift(key) }]
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
  # Ranges are interpreted as start/end pairs, respecting the exclusion of the end point.
  #
  # @param [Symbol] comparator The comparator to get the appropriate Squeel comparator for.
  # @param value The value to be comparing against.
  # @return [Array<Array<(Symbol, Object)>>] An array of comparisons, each with the comparator
  #   to use, and the value to compare against.
  def squeel_comparator_for(comparator, value)
    case value
    when Array then comparator_for_array(comparator, value)
    when Range then comparator_for_range(comparator, value)
    else [:&, [[comparator, value]]]
    end
  end

  # Maps the given comparator to the IN/NOT IN operator.
  #
  # @param [Symbol] comparator The comparator to get the SqueeL comparator for.
  # @param [Array] value The acceptable/rejected values.
  # @return [Array<(Symbol, Array<(Symbol, Object)>)>] The combinator, and an array of comparisons,
  #   each with the comparator to use, and the value to compare against.
  def comparator_for_array(comparator, value)
    case comparator
    when :== then [:&, [[:>>, value]]]
    when :!= then [:&, [[:<<, value]]]
    end
  end

  # Maps the given comparator to a range comparison.
  #
  # @param [Symbol] comparator The comparator to get the Squeel comparator for.
  # @param [Range] value The acceptable/rejected values.
  # @return [Array<(Symbol, Array<(Symbol, Object)>)>] The combinator, and an array of comparisons,
  #   each with the comparator to use, and the value to compare against.
  def comparator_for_range(comparator, value)
    if value.exclude_end?
      comparator_for_exclusive_range(comparator, value)
    else
      comparator_for_inclusive_range(comparator, value)
    end
  end

  # Maps the given comparator to a range comparison.
  #
  # @param [Symbol] comparator The comparator to get the Squeel comparator for.
  # @param [Range] value The acceptable/rejected values.
  # @return [Array<Array<(Symbol, Object)>>] An array of comparisons, each with the comparator
  #   to use, and the value to compare against.
  def comparator_for_exclusive_range(comparator, value)
    case comparator
    when :== then [:&, [[:>=, value.first], [:<, value.last]]]
    when :!= then [:|, [[:<, value.first], [:>=, value.last]]]
    end
  end

  # Maps the given comparator to a range comparison.
  #
  # @param [Symbol] comparator The comparator to get the Squeel comparator for.
  # @param [Range] value The acceptable/rejected values.
  # @return [Array<Array<(Symbol, Object)>>] An array of comparisons, each with the comparator
  #   to use, and the value to compare against.
  def comparator_for_inclusive_range(comparator, value)
    case comparator
    when :== then [:&, [[:>=, value.first], [:<=, value.last]]]
    when :!= then [:|, [[:<, value.first], [:>, value.last]]]
    end
  end
end
