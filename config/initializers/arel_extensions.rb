module Arel
  module Nodes
    class TsVector < Arel::Nodes::Node
      include Arel::Predications

      attr_reader :expressions, :config

      def initialize(expressions, config = "english")
        @expressions = Array(expressions)
        @config = config
      end
    end

    class TsQuery < Arel::Nodes::Node
      attr_reader :query, :config

      def initialize(query, config = "english")
        @query = query
        @config = config
      end
    end

    class WebTsQuery < TsQuery; end
    class PlainTsQuery < TsQuery; end
    class PhraseTsQuery < TsQuery; end

    class TsHeadline < Arel::Nodes::Node
      attr_reader :expression, :query, :options, :config

      def initialize(expression, query, options = {}, config = "english")
        @expression = expression
        @query = query
        @options = options
        @config = config
      end
    end

    class TsRankBase < Arel::Nodes::Node
      attr_reader :vector, :query, :normalization

      def initialize(vector, query, normalization = nil)
        @vector = vector
        @query = query
        @normalization = normalization
      end
    end

    class TsRank < TsRankBase; end
    class TsRankCd < TsRankBase; end
  end

  module FullTextSearch
    def ts_vector(*expressions, config: "english")
      Nodes::TsVector.new(expressions, config)
    end

    def ts_query(query, config: "english")
      Nodes::TsQuery.new(query, config)
    end

    def web_ts_query(query, config: "english")
      Nodes::WebTsQuery.new(query, config)
    end

    def plain_ts_query(query, config: "english")
      Nodes::PlainTsQuery.new(query, config)
    end

    def phrase_ts_query(query, config: "english")
      Nodes::PhraseTsQuery.new(query, config)
    end

    def ts_headline(expression, query, options: {}, config: "english")
      Nodes::TsHeadline.new(expression, query, options, config)
    end

    def ts_rank(vector, query, normalization: nil)
      Nodes::TsRank.new(vector, query, normalization)
    end

    def ts_rank_cd(vector, query, normalization: nil)
      Nodes::TsRankCd.new(vector, query, normalization)
    end
  end

  module Predications
    def ts_match(other)
      Nodes::InfixOperation.new("@@", self, other)
    end
  end

  module Visitors
    class PostgreSQL
      private

      def visit_Arel_Nodes_TsVector(o, collector)
        collector << "to_tsvector("
        collector << quote(o.config) << ", "
        collector = inject_join(o.expressions, collector, " || ' ' || ")
        collector << ")"
        collector
      end

      def visit_Arel_Nodes_TsQuery(o, collector)
        collector << "to_tsquery("
        collector << quote(o.config) << ", "
        collector << quote(o.query)
        collector << ")"
      end

      def visit_Arel_Nodes_WebTsQuery(o, collector)
        collector << "websearch_to_tsquery("
        collector << quote(o.config) << ", "
        collector << quote(o.query)
        collector << ")"
      end

      def visit_Arel_Nodes_PlainTsQuery(o, collector)
        collector << "plainto_tsquery("
        collector << quote(o.config) << ", "
        collector << quote(o.query)
        collector << ")"
      end

      def visit_Arel_Nodes_PhraseTsQuery(o, collector)
        collector << "phraseto_tsquery("
        collector << quote(o.config) << ", "
        collector << quote(o.query)
        collector << ")"
      end

      def visit_Arel_Nodes_TsHeadline(o, collector)
        collector << "ts_headline("
        collector << quote(o.config) << ", "
        collector = visit o.expression, collector
        collector << ", "
        collector = visit o.query, collector

        if o.options.present?
          collector << ", "
          collector << quote(format_headline_options(o.options))
        end

        collector << ")"
      end

      def visit_Arel_Nodes_TsRank(o, collector)
        collector << "ts_rank("
        collector = visit o.vector, collector
        collector << ", "
        collector = visit o.query, collector
        if o.normalization
          collector << ", "
          collector << o.normalization.to_s
        end
        collector << ")"
      end

      def visit_Arel_Nodes_TsRankCd(o, collector)
        collector << "ts_rank_cd("
        collector = visit o.vector, collector
        collector << ", "
        collector = visit o.query, collector
        if o.normalization
          collector << ", "
          collector << o.normalization.to_s
        end
        collector << ")"
      end

      private

      def format_headline_options(options)
        options.map do |key, value|
          case key.to_s
          when "start_sel", "stop_sel"
            "#{key.to_s.camelize}=#{value}"
          else
            "#{key.to_s.camelize}=#{value}"
          end
        end.join(", ")
      end
    end
  end
end

# Include our extensions
Arel::Table.include(Arel::FullTextSearch)
