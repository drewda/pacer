require 'parslet'

module Pacer
  module Filter
    module ExpressionFilter
      class Parser < Parslet::Parser
        class << self
          def reset
            @parser = nil
          end

          def parse(str)
            @parser ||= new
            @parser.parse str
          end
        end

        rule(:lparen)    { str('(') >> space? }
        rule(:rparen)    { str(')') >> space? }
        rule(:space)     { match('\s').repeat(1) }
        rule(:space?)    { space.maybe }

        rule(:integer)   { match('[0-9]').repeat(1).as(:int) >> space? }
        rule(:float)     { (match('[0-9]').repeat(1) >> str('.') >> match('[0-9]').repeat(1) ).as(:float) >> space? }
        rule(:boolean)   { ( match('true') | match('false') ).as(:bool) >> space? }
        rule(:dq_string) { (str('"') >> ( str('\\') >> any | str('"').absnt? >> any ).repeat.as(:str) >> str('"')) >> space? }
        rule(:sq_string) { (str("'") >> ( str('\\') >> any | str("'").absnt? >> any ).repeat.as(:str) >> str("'")) >> space? }
        rule(:string)    { dq_string | sq_string }

        rule(:property_string) { (str("{") >> ( str('\\') >> any | str("}").absnt? >> any ).repeat.as(:prop) >> str("}")) >> space? }

        rule(:identifier)      { match['[a-zA-Z]'] >> match('[a-zA-Z0-9_]').repeat }
        rule(:variable)        { str(':') >> identifier.as(:var) >> space? }
        rule(:proc_variable)   { str('&') >> identifier.as(:proc) >> space? }

        rule(:property)   { identifier.as(:prop) >> space? }

        rule(:comparison) { (str('!=') | str('>=') | str('<=') | str('==') | match("[=><]")).as(:op) >> space? }
        rule(:bool_and)   { str('and') >> space? }
        rule(:bool_or)    { str('or') >> space? }
        rule(:data)       { boolean | variable | proc_variable | property | property_string | float | integer | string }
        rule(:negate)     { (str('not') | str('!')).as(:negate).maybe >> space? }

        rule(:statement)  { (negate >> ( data.as(:left) >> comparison >> data.as(:right) | proc_variable )).as(:statement) >> space? }
        rule(:group)      { (negate >> lparen >> expression >> rparen).as(:group) >> space? }
        rule(:and_group)  { ((statement | group) >> (bool_and >> (statement | group)).repeat(1) >> or_group.maybe).as(:and) }
        rule(:or_group)   { ((bool_or >> (and_group | group | statement)).repeat(1)).as(:or) >> space? }
        rule(:expression) { (and_group | group | statement) >> or_group.maybe }

        root :expression
      end
    end
  end
end
