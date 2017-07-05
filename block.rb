class Block
  attr_reader :prev, :value, :nonce, :sig
  def initialize(value, prev = nil)
    @prev = prev
    @value = value
    generate_nonce!
  end

  def sig
    @sig ||= Digest::SHA256.base64digest(contents)
  end

  def history
    (prev.try(:history) || []) + [value]
  end

  def predecessors
    (prev.try(:predecessors) || []).push(self)
  end

  def append(value)
    self.class.new(value, self)
  end

  def inspect
    preds = predecessors
    preds
      .map { |block| { value: block.value, nonce: block.nonce } }
      .map(&:to_s)
      .join("\n")
      .prepend("Block #{preds.length}: \"#{value}\"\n Chain: \n")
  end

  def verified?
    Digest::SHA256.base64digest(contents)[0..1] == '00'
  end

  def chain_verified?
    predecessors.all?(&:verified?)
  end

  private

  def generate_nonce!
    @nonce = rand(2**62) until verified?
  end

  def contents
    [prev.try(:sig), value, nonce].to_s
  end
end

b = Block.new("kill bill 1").append("kill bill 2").append("kill bill 3")
