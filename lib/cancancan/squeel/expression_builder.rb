# frozen_string_literal: true
# Builds Squeel expressions from the given scope, model class, and a hash of conditions.
#
# This is used by building a set of rules for retrieving all accessible records, as well as for
# building queries instead of loading all records into memory.
module CanCanCan::Squeel::ExpressionBuilder
  module_function

  # Builds a new Squeel expression node given a model class, the comparator, and the conditions.
  #
  # @param squeel The Squeel context. This is the value of +self+ within a +where+ DSL block.
  # @param [Class] model_class The model class which the conditions reference.
  # @param [Symbol] comparator The comparator to use when generating the comparison.
  # @param [Hash] conditions The values to compare the given node's attributes against.
  def build(squeel, model_class, comparator, conditions)
    build_expression_node(squeel, model_class, comparator, conditions, true)
  end

  # Builds a new Squeel expression node.
  #
  # @param node The parent node context.
  # @param [Class] model_class The model class which the conditions reference.
  # @param [Symbol] comparator The comparator to use when generating the comparison.
  # @param [Hash] conditions The values to compare the given node's attributes against.
  # @param [Boolean] root True if the node being built is from the root. The root node is special
  #   because it does not mutate itself; all other nodes do.
  def build_expression_node(node, model_class, comparator, conditions, root = false)
    conditions.reduce(nil) do |left_expression, (key, value)|
      comparison_node = build_comparison_node(root ? node : node.dup, model_class, key,
                                              comparator, value)
      if left_expression
        left_expression & comparison_node
      else
        comparison_node
      end
    end
  end
  module_function :build_expression_node

  # Builds a comparison node for the given key and value.
  #
  # @param node The node context to build the comparison.
  # @param [Class] model_class The model class which the conditions reference.
  # @param [Symbol] key The column to compare against.
  # @param [Symbol] comparator The comparator to compare the column against the value.
  # @param value The value to compare the column against.
  def build_comparison_node(node, model_class, key, comparator, value)
    if value.is_a?(Hash)
      reflection = model_class.reflect_on_association(key)
      build_expression_node(node.__send__(key), reflection.klass, comparator, value)
    else
      key, comparator, value = CanCanCan::Squeel::AttributeMapper.
                               squeel_comparison_for(model_class, key, comparator, value)
      node.__send__(key).public_send(comparator, value)
    end
  end
end
