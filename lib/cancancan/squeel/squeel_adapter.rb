# frozen_string_literal: true
class CanCanCan::Squeel::SqueelAdapter < CanCan::ModelAdapters::AbstractAdapter
  include CanCanCan::Squeel::ExpressionCombinator

  ALWAYS_TRUE = CanCanCan::Squeel::ExpressionCombinator::ALWAYS_TRUE
  ALWAYS_FALSE = CanCanCan::Squeel::ExpressionCombinator::ALWAYS_FALSE

  def self.for_class?(model_class)
    model_class <= ActiveRecord::Base
  end

  def self.override_condition_matching?(subject, name, _)
    match_relation?(subject, name) || match_enum?(subject, name)
  end

  def self.matches_condition?(subject, name, value)
    if match_relation?(subject, name)
      matches_relation?(subject, name, value)
    elsif match_enum?(subject, name)
      matches_enum?(subject, name, value)
    else
      false
    end
  end

  # Overrides condition matching for enums.
  def self.match_enum?(subject, name)
    klass = subject.class
    klass.respond_to?(:defined_enums) && klass.defined_enums.include?(name.to_s)
  end
  private_class_method :match_enum?

  # Overrides condition matching for enums.
  def self.matches_enum?(subject, name, value)
    # Get the mapping from enum strings to values.
    enum = subject.class.public_send(name.to_s.pluralize)

    # Get the value of the attribute as an integer.
    attribute = enum[subject.public_send(name)]

    # Check to see if the value matches the condition.
    value.is_a?(Enumerable) ? value.include?(attribute) : attribute == value
  end
  private_class_method :matches_enum?

  def self.match_relation?(subject, name)
    subject_attribute = subject.public_send(name)
    subject_attribute.is_a?(ActiveRecord::Relation) && !subject_attribute.loaded
  end
  private_class_method :match_relation?

  def self.matches_relation?(subject, name, value)
    relation = subject.public_send(name)
    klass = subject.class.reflect_on_association(name).klass

    relation.where { CanCanCan::Squeel::ExpressionBuilder.build(self, klass, :==, value) }.any?
  end
  private_class_method :matches_relation?

  def database_records
    # TODO: Handle overridden scopes.
    relation.distinct
  end

  private

  # Builds a relation that expresses the set of provided rules.
  #
  # This first joins all the tables specified in the rules, then builds the corresponding Squeel
  # expression for the conditions.
  def relation
    join_scope = @rules.reduce(@model_class.where(nil)) do |scope, rule|
      add_joins_to_scope(scope, build_join_list(rule.conditions))
    end

    add_conditions_to_scope(join_scope)
  end

  # Builds an array of joins for the given conditions hash.
  #
  # For example:
  #
  # a: { b: { c: 3 }, d: { e: 4 }} => [[:a, :b], [:a, :d]]
  #
  # @param [Hash] conditions The conditions to build the joins.
  # @return [Array<Array<Symbol>>] The joins needed to satisfy the given conditions
  def build_join_list(conditions)
    conditions.flat_map do |key, value|
      if value.is_a?(Hash)
        [[key]].concat(build_join_list(value).map { |join| Array(join).unshift(key) })
      else
        []
      end
    end
  end

  # Builds a relation, outer joined on the provided associations.
  #
  # @param [ActiveRecord::Relation] scope The current scope to add the joins to.
  # @param [Array<Array<Symbol>>] joins The set of associations to outer join with.
  # @return [ActiveRecord::Relation] The built relation.
  def add_joins_to_scope(scope, joins)
    joins.reduce(scope) do |result, join|
      result.joins do
        join.reduce(self) do |relation, association|
          relation.__send__(association).outer
        end
      end
    end
  end

  # Adds the rule conditions to the scope.
  #
  # This builds Squeel expression for each rule, and combines the expression with those to the left
  # using a fold-left.
  #
  # The rules provided by Cancancan are in reverse order, i.e. the lowest priority rule is first.
  #
  # @param [ActiveRecord::Relation] scope The scope to add the rule conditions to.
  def add_conditions_to_scope(scope)
    adapter = self
    rules = @rules

    scope.where do
      rules.reverse.reduce(ALWAYS_FALSE) do |left_expression, rule|
        adapter.send(:combine_expression_with_rule, self, left_expression, rule)
      end
    end
  end

  # Combines the given expression with the new rule.
  #
  # @param squeel The Squeel scope.
  # @param left_expression The Squeel expression for all preceding rules.
  # @param [CanCan::Rule] rule The rule being added.
  # @return [Squeel::Nodes::Node] If the rule has an expression.
  def combine_expression_with_rule(squeel, left_expression, rule)
    right_expression = build_expression_from_rule(squeel, rule)

    operator = rule.base_behavior ? :| : :&
    combine_squeel_expressions(left_expression, operator, right_expression)
  end

  # Builds a Squeel expression representing the rule's conditions.
  #
  # @param squeel The Squeel scope.
  # @param [CanCan::Rule] rule The rule being built.
  # @return [Squeel::Nodes::Node] The expression presenting the rule's conditions.
  def build_expression_from_rule(squeel, rule)
    if rule.conditions.empty?
      rule.base_behavior ? ALWAYS_TRUE : ALWAYS_FALSE
    else
      comparator = rule.base_behavior ? :== : :!=
      CanCanCan::Squeel::ExpressionBuilder.build(squeel, @model_class, comparator, rule.conditions)
    end
  end
end
