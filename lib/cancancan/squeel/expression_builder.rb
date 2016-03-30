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
  # @return [Array<(Squeel::Nodes::Node, Array<Array<Symbol>>)>] A tuple containing the Squeel
  #   expression representing the rule's conditions, as well as an array of joins which the Squeel
  #   expression must be joined to.
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
  # @return [Array<(Squeel::Nodes::Node, Array<Array<Symbol>>)>] A tuple containing the Squeel
  #   expression representing the rule's conditions, as well as an array of joins which the Squeel
  #   expression must be joined to.
  def build_expression_node(node, model_class, comparator, conditions, root = false)
    conditions.reduce([nil, []]) do |(left_expression, joins), (key, value)|
      comparison_node, node_joins = build_comparison_node(root ? node : node.dup, model_class,
                                                          key, comparator, value)
      if left_expression
        [left_expression & comparison_node, joins.concat(node_joins)]
      else
        [comparison_node, node_joins]
      end
    end
  end

  # Builds a comparison node for the given key and value.
  #
  # @param node The node context to build the comparison.
  # @param [Class] model_class The model class which the conditions reference.
  # @param [Symbol] key The column to compare against.
  # @param [Symbol] comparator The comparator to compare the column against the value.
  # @param value The value to compare the column against.
  def build_comparison_node(node, model_class, key, comparator, value)
    if value.is_a?(Hash)
      build_association_comparison_node(node, model_class, key, comparator, value)
    else
      build_scalar_comparison_node(node, model_class, key, comparator, value)
    end
  end

  # Builds a comparison node for the given association and association attributes.
  #
  # @param node The node context to build the comparison.
  # @param [Class] model_class The model class which the conditions reference.
  # @param [Symbol] key The association to compare against.
  # @param [Symbol] comparator The comparator to compare the column against the value.
  # @param [Hash] value The attributes to compare the column against.
  def build_association_comparison_node(node, model_class, key, comparator, value)
    reflection_class = model_class.reflect_on_association(key).klass
    expression, joins = build_expression_node(node.__send__(key), reflection_class, comparator,
                                              value)
    [expression, joins.map { |join| join.unshift(key) }.unshift([key])]
  end

  # Builds a comparison node for the given attribute and value.
  #
  # @param node The node context to build the comparison.
  # @param [Class] model_class The model class which the conditions reference.
  # @param [Symbol] key The column to compare against.
  # @param [Symbol] comparator The comparator to compare the column against the value.
  # @param value The value to compare the column against.
  def build_scalar_comparison_node(node, model_class, key, comparator, value)
    combinator, comparisons = CanCanCan::Squeel::AttributeMapper.
                              squeel_comparison_for(model_class, key, comparator, value)
    attribute = node.__send__(comparisons.first.first)

    expression = comparisons.reduce(nil) do |left_expression, (_, comparator, value)|
      right_expression = attribute.dup.public_send(comparator, value)
      next right_expression unless left_expression

      left_expression.public_send(combinator, right_expression)
    end

    [expression, []]
  end
end
