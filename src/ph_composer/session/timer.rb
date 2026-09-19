# frozen_string_literal: true

module PhComposer
  # One pending zero-delay UI timer at most: repeated requests before it fires coalesce into one run.
  class CoalescedTimer
    def initialize
      @timer = nil
    end

    def schedule(&block)
      return false if pending?

      @timer = UI.start_timer(0.0, false) do
        @timer = nil
        block.call
      end
      true
    end

    def cancel
      return false unless pending?

      self.class.stop(@timer)
      @timer = nil
      true
    end

    def pending?
      !@timer.nil?
    end

    def self.stop(timer)
      UI.stop_timer(timer) if timer && UI.respond_to?(:stop_timer)
    end
  end
end
