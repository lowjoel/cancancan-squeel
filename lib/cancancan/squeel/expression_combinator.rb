module CanCanCan::Squeel::ExpressionCombinator
  # Combines two Squeel expressions.
  #
  # @param [Squeel::Nodes::Node] left_expression The left expression.
  # @param [Symbol] operator The operator to combine with. This must be either +:&+ or +:|+.
  # @param [Squeel::Nodes::Node] right_expression The right expression.
  # @return [Squeel::Nodes::Node] The combination of the given expressions.
  def combine_squeel_expressions(left_expression, operator, right_expression)
    left_expression.public_send(operator, right_expression)
  end
end
