require 'time'
require 'digest'

class Block
	attr_accessor :prev_block, :time_stamp, :data, :hash
	
	def initialize(prev_block, data)
		@prev_block = prev_block
		@time_stamp = Time.now.getutc
		@data = data
		@hash = calculate_hash()
	end
	
	def is_block_chain_valid
		if hash.eql? calculate_hash()
			if prev_block
				prev_block.is_block_chain_valid
			else
				true
			end
		else 
			false
		end
	end
	
	private
	
	def calculate_hash
		Digest::SHA256.hexdigest "#{prev_block.hash}#{time_stamp}#{data}"
	end
	
end

b1 = Block.new(nil, "Hello from Block 1!")
b2 = Block.new(b1, "Hello from Block 2!")
b3 = Block.new(b2, "Hello from Block 3!")

puts b3.is_block_chain_valid

b1.data = "Hello from fake Block 1!"

puts b3.is_block_chain_valid