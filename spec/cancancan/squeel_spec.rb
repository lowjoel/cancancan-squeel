require 'spec_helper'

RSpec.describe CanCanCan::Squeel do
  it 'has a version number' do
    expect(CanCanCan::Squeel::VERSION).not_to be nil
  end

  let(:ability) { double.extend(CanCan::Ability) }

  with_database(:sqlite) do
    it 'respects scope on included associations' do
      ability.can :read, [Parent, Child]

      parent = Parent.create!
      child1 = Child.create!(parent: parent, created_at: 1.hours.ago)
      child2 = Child.create!(parent: parent, created_at: 2.hours.ago)

      parents = Parent.accessible_by(ability).order(created_at: :asc).includes(:children)
      expect(parents.first.children).to eq([child2, child1])
    end

    it 'supports repeated tables in deeply nested conditions' do
      parent1 = Parent.create!
      parent2 = Parent.create!
      ability.can :read, Parent, children: {
        other_parent: {
          id: parent1.id
        }
      }

      # check that we are not directly accessible
      expect(Parent.accessible_by(ability)).to be_empty

      _child = Child.create!(parent: parent2, other_parent: parent1)
      expect(Parent.accessible_by(ability)).to contain_exactly(parent2)
    end

    it 'allows using accessible_by on a chained scope' do
      parent1 = Parent.create!
      parent2 = Parent.create!
      parent3 = Parent.create!
      _child1 = Child.create!(parent: parent1, other_parent: parent2)
      _child2 = Child.create!(parent: parent2, other_parent: parent3)
      ability.can :read, Parent, other_parents: { id: parent3.id }

      expect(parent1.other_parents.accessible_by(ability)).to contain_exactly(parent2)
    end

    it 'allows combining conditions on the same object' do
      purple = Shape.create!(color: :purple, primary: false)

      ability.can(:read, Shape, color: Shape.colors[:purple], primary: false)

      accessible = Shape.accessible_by(ability)
      expect(accessible).to contain_exactly(purple)
    end

    it 'allows filters on enums' do
      red = Shape.create!(color: :red)
      green = Shape.create!(color: :green)
      blue = Shape.create!(color: :blue)

      # A condition with a single value.
      ability.can(:read, Shape, color: Shape.colors[:green])

      expect(ability.cannot?(:read, red)).to be true
      expect(ability.can?(:read, green)).to be true
      expect(ability.cannot?(:read, blue)).to be true

      accessible = Shape.accessible_by(ability)
      expect(accessible).to contain_exactly(green)

      # A condition with multiple values.
      ability.can(:update, Shape, color: [Shape.colors[:red],
                                          Shape.colors[:blue]])

      expect(ability.can?(:update, red)).to be true
      expect(ability.cannot?(:update, green)).to be true
      expect(ability.can?(:update, blue)).to be true

      accessible = Shape.accessible_by(ability, :update)
      expect(accessible).to contain_exactly(red, blue)
    end

    context 'when multiple rules govern the same resource' do
      it 'prioritises rules coming last' do
        ability.cannot(:read, Shape, color: Shape.colors[:red])
        ability.can(:read, Shape)
        ability.cannot(:read, Shape, color: Shape.colors[:blue])

        red = Shape.create!(color: :red)
        green = Shape.create!(color: :green)
        _blue = Shape.create!(color: :blue)
        accessible = Shape.accessible_by(ability)

        expect(accessible).to contain_exactly(red, green)
      end
    end
  end
end
