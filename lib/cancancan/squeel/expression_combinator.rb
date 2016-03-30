# frozen_string_literal: true
module CanCanCan::Squeel::ExpressionCombinator
  # This true expression is used to indicate a condition that is always satisfied.
  ALWAYS_TRUE = Squeel::Nodes::Predicate.new(Squeel::Nodes::Literal.new('1'), :eq, 1).freeze

  # This true expression is used to indicate a condition that is never satisfied.
  ALWAYS_FALSE = Squeel::Nodes::Predicate.new(Squeel::Nodes::Literal.new('1'), :eq, 0).freeze

  # Combines two Squeel expressions. This is aware of the +ALWAYS_TRUE+ and +ALWAYS_FALSE+
  # constants and performs simplification.
  #
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Array] left_expression_joins An array of joins which the Squeel expression must be
  #   joined to.
  # @param [Symbol] operator The operator to combine with. This must be either +:&+ or +:|+.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @param [Array] right_expression_joins An array of joins which the Squeel expression must be
  #   joined to.
  # @return [Array<(Squeel::Nodes::Node, Array)>] A tuple containing the combination of the given
  #   expressions, as well as an array of joins which the Squeel expression must be joined to.
  def combine_squeel_expressions(left_expression, left_expression_joins, operator,
                                 right_expression, right_expression_joins)
    case operator
    when :& then conjunction_expressions(left_expression, left_expression_joins,
                                         right_expression, right_expression_joins)
    when :| then disjunction_expressions(left_expression, left_expression_joins,
                                         right_expression, right_expression_joins)
    else
      raise ArgumentError, "#{operator} must either be :& or :|"
    end
  end

  # Computes the conjunction of the two Squeel expressions.
  #
  # Boolean simplification is done for the +ALWAYS_TRUE+ and +ALWAYS_FALSE+ values.
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Array] left_expression_joins An array of joins which the Squeel expression must be
  #   joined to.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @param [Array] right_expression_joins An array of joins which the Squeel expression must be
  #   joined to.
  # @return [Array<(Squeel::Nodes::Node, Array)>] A tuple containing the conjunction of the left and
  #   right expressions, as well as an array of joins which the Squeel expression must be joined to.
  def conjunction_expressions(left_expression, left_expression_joins, right_expression,
                              right_expression_joins)
    if left_expression == ALWAYS_FALSE || right_expression == ALWAYS_FALSE
      [ALWAYS_FALSE, []]
    elsif left_expression == ALWAYS_TRUE
      [right_expression, right_expression_joins]
    elsif right_expression == ALWAYS_TRUE
      [left_expression, left_expression_joins]
    else
      [left_expression & right_expression, left_expression_joins + right_expression_joins]
    end
  end

  # Computes the disjunction of the two Squeel expressions.
  #
  # Boolean simplification is done for the +ALWAYS_TRUE+ and +ALWAYS_FALSE+ values.
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Array] left_expression_joins An array of joins which the Squeel expression must be
  #   joined to.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @param [Array] right_expression_joins An array of joins which the Squeel expression must be
  #   joined to.
  # @return [Array<(Squeel::Nodes::Node, Array)>] A tuple containing the disjunction of the left and
  #   right expressions, as well as an array of joins which the Squeel expression must be joined to.
  def disjunction_expressions(left_expression, left_expression_joins, right_expression,
                              right_expression_joins)
    if left_expression == ALWAYS_TRUE || right_expression == ALWAYS_TRUE
      [ALWAYS_TRUE, []]
    elsif left_expression == ALWAYS_FALSE
      [right_expression, right_expression_joins]
    elsif right_expression == ALWAYS_FALSE
      [left_expression, left_expression_joins]
    else
      [left_expression | right_expression, left_expression_joins + right_expression_joins]
    end
  end
end
