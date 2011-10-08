module Redeye
  module Nodes

    TAB = '  ' # Two spaces for pretty printing

    module Base
      def to_s(indent = '', name = node_name)
        tree = "\n#{indent}#{name}"
        children.each do |child|
          tree << child.to_s(indent + TAB)
        end
        tree
      end

      def node_name
        self.class.name.split('::').last
      end

      def children
        []
      end
    end

    class Block
      include Base

      def initialize(nodes)
        @nodes = nodes
      end

      def children
        [ @nodes ]
      end
    end

    class Literal
      include Base

      def initialize(value)
        @value = value
      end

      def to_s(indent)
        " \"#{@value.to_s}\""
      end
    end

    class Value
      include Base

      def initialize(value)
        @value = value
      end

      def children
        [ @value ]
      end
    end

    class Assign
      include Base

      def initialize(variable, value)
        @variable = variable
        @value = value
      end

      def children
        [ @variable , @value ]
      end
    end
  end
end
