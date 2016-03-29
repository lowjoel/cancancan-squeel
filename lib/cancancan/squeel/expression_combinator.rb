module CanCanCan::Squeel::ExpressionCombinator
  # This true expression is used to indicate a condition that is always satisfied.
  ALWAYS_TRUE = Squeel::Nodes::Predicate.new(Squeel::Nodes::Literal.new('1'), :eq, 1).freeze

  # This true expression is used to indicate a condition that is never satisfied.
  ALWAYS_FALSE = Squeel::Nodes::Predicate.new(Squeel::Nodes::Literal.new('1'), :eq, 0).freeze

  # Combines two Squeel expressions. This is aware of the +ALWAYS_TRUE+ and +ALWAYS_FALSE+
  # constants and performs simplification.
  #
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Symbol] operator The operator to combine with. This must be either +:&+ or +:|+.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @return [Squeel::Nodes::Node] The combination of the given expressions.
  def combine_squeel_expressions(left_expression, operator, right_expression)
    case operator
    when :& then conjunction_expressions(left_expression, right_expression)
    when :| then disjunction_expressions(left_expression, right_expression)
    else
      raise ArgumentError, "#{operator} must either be :& or :|"
    end
  end

  # Computes the conjunction of the two Squeel expressions.
  #
  # Boolean simplification is done for the +ALWAYS_TRUE+ and +ALWAYS_FALSE+ values.
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @return [Squeel::Nodes::Node] The conjunction of the left and right expression.
  def conjunction_expressions(left_expression, right_expression)
    if left_expression == ALWAYS_FALSE || right_expression == ALWAYS_FALSE
      ALWAYS_FALSE
    elsif left_expression == ALWAYS_TRUE
      right_expression
    elsif right_expression == ALWAYS_TRUE
      left_expression
    else
      left_expression & right_expression
    end
  end

  # Computes the disjunction of the two Squeel expressions.
  #
  # Boolean simplification is done for the +ALWAYS_TRUE+ and +ALWAYS_FALSE+ values.
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @return [Squeel::Nodes::Node] The disjunction of the left and right expression.
  def disjunction_expressions(left_expression, right_expression)
    if left_expression == ALWAYS_TRUE || right_expression == ALWAYS_TRUE
      ALWAYS_TRUE
    elsif left_expression == ALWAYS_FALSE
      right_expression
    elsif right_expression == ALWAYS_FALSE
      left_expression
    else
      left_expression | right_expression
    end
  end
end
