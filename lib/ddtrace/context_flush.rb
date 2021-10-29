# typed: true
module Datadog
  module ContextFlush
    # Consumes only completed traces (where all spans have finished)
    class Finished
      # Consumes and returns completed traces (where all spans have finished)
      # from the provided +context+, if any.
      #
      # Any traces consumed are removed from +context+ as a side effect.
      #
      # @return [Array<Span>] trace to be flushed, or +nil+ if the trace is not finished
      def consume!(context)
        trace = get_trace(context)
        trace if trace && trace.sampled
      end

      protected

      def get_trace(context)
        context.get
      end
    end

    # Performs partial trace flushing to avoid large traces residing in memory for too long
    class Partial
      # Start flushing partial trace after this many active spans in one trace
      DEFAULT_MIN_SPANS_FOR_PARTIAL_FLUSH = 500

      def initialize(options = {})
        @min_spans_for_partial = options.fetch(:min_spans_before_partial_flush, DEFAULT_MIN_SPANS_FOR_PARTIAL_FLUSH)
      end

      # Consumes and returns completed or partially completed
      # traces from the provided +context+, if any.
      #
      # Partially completed traces, where not all spans have finished,
      # will only be returned if there are at least
      # +@min_spans_for_partial+ finished spans.
      #
      # Any spans consumed are removed from +context+ as a side effect.
      #
      # @return [Array<Span>] partial or complete trace to be flushed, or +nil+ if no spans are finished
      def consume!(context)
        return unless partial_flush?(context)

        trace = get_trace(context)
        trace if trace && trace.sampled
      end

      def partial_flush?(context)
        return false unless context.sampled?
        return true if context.finished?
        return false if context.finished_span_count < @min_spans_for_partial

        true
      end

      protected

      def get_trace(context)
        partial_trace(context)
      end

      private

      def partial_trace(context)
        trace = context.get_partial_trace(&:finished?)
        return if trace.empty?
        # TODO: Remove this; do this when trace is being serialized instead.
        trace.annotate!
        trace
      end
    end
  end
end
