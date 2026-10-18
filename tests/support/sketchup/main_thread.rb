# frozen_string_literal: true

# The host's API belongs to its main thread: SketchUp runs Ruby threads only while the main thread
# yields, and nothing in its API is documented as safe from another thread. The extension's loopback
# servers keep every Sketchup and UI call on the main thread; the stub refuses one made elsewhere, so a
# worker that strays fails offline instead of corrupting a host.
#
# Each method is wrapped in place, not through `prepend`: Minitest's `stub` aliases the method it
# replaces, and an alias of a prepended wrapper would call itself.
module StubMainThreadOnly
  def self.guard(target)
    owner = target.singleton_class
    owner.public_instance_methods(false).each do |name|
      original = owner.instance_method(name)
      owner.send(:define_method, name) do |*arguments, &block|
        raise ThreadError, "#{target}.#{name} called off the main thread" unless Thread.current.equal?(Thread.main)

        original.bind(self).call(*arguments, &block)
      end
      owner.send(:ruby2_keywords, name)
    end
  end
end

StubMainThreadOnly.guard(Sketchup)
StubMainThreadOnly.guard(UI)
