require 'active_support'
require 'active_support/core_ext/object'
require 'digest'
require 'pry'
require_relative 'block'

class MerkleTree
  attr_reader :root
  def initialize(blocks)
    leaves = blocks.map { |block| MerkleNode.new(nil, nil, nil, block) }
    @root = construct_parents!(leaves)
    set_parent_pointers!
  end

  def construct_parents!(nodes)
    return nodes.first if nodes.length == 1
    child_nodes = nodes.each_slice(2).map do |left, right|
      MerkleNode.new(left, right)
    end
    construct_parents!(child_nodes)
  end

  def set_parent_pointers!(parent = @root)
    [parent.left, parent.right].compact.each do |child|
      child.parent = parent
      set_parent_pointers!(child)
    end
  end

  def inspect
    root.pre_order.inspect
  end
end

class MerkleNode
  attr_accessor :left, :right, :block, :digest, :parent
  def initialize(left, right, parent = nil, block = nil)
    @left = left
    @right = right
    @parent = parent
    @block = block
  end

  def digest
    @digest ||= Digest::SHA256.base64digest(hash_input)
  end

  def pre_order
    [self, left.try(:pre_order), right.try(:pre_order)].compact.flatten
  end

  def inspect
    [block, digest].to_s
  end

  def valid_branch?(current_node = self)
    return false if !valid?
    return true if parent.blank?
    parent.valid_branch?
  end

  def valid?
    digest == Digest::SHA256.base64digest(hash_input)
  end

  private

  def hash_input
    if block.present?
      block.sig
    else
      [left.try(:digest), right.try(:digest)].compact.join
    end
  end
end

t = MerkleTree.new(Block.new("kill bill 1").append("kill bill 2").append("kill bill 3").predecessors)
