require 'time'
require 'digest'
require 'openssl'
require 'securerandom'

PEM_PASSWORD = 'PQVF3ZbCjY5MbpC5'

class Transaction

	attr_accessor :id, :funds 
	
	def initialize(sender_wallet, receiver_wallet, funds, signature)
		@id = "#{SecureRandom.uuid}"
		@sender_wallet = sender_wallet
		@receiver_wallet = receiver_wallet
		@funds = funds
		@signature = signature
	end
	
	def process()
		if is_singnature_valid
			sender_wallet.outcoming_transactions.push(self)
			receiver_wallet.incoming_transactions.push(self)
		end
	end
	
	private
	
	attr_accessor :sender_wallet, :receiver_wallet, :signature
	
	def is_singnature_valid()
		data = "#{sender_wallet.public_key}#{receiver_wallet.public_key}#{funds}"
		OpenSSL::PKey::RSA.new(sender_wallet.public_key, PEM_PASSWORD).verify(OpenSSL::Digest::SHA256.new, signature, data)
	end
	
end

class Wallet

	attr_accessor :private_key, :public_key, :incoming_transactions, :outcoming_transactions
	
	def initialize(initial_amount)
		rsa_key = OpenSSL::PKey::RSA.new(2048)
		cipher =  OpenSSL::Cipher::Cipher.new('des3')
		@initial_amount = initial_amount
		@private_key = rsa_key.to_pem(cipher,PEM_PASSWORD)
		@public_key = rsa_key.public_key.to_pem
		@incoming_transactions = []
		@outcoming_transactions = []
	end
	
	def calculate_balance()
		amount = initial_amount
		incoming_transactions.each do |incoming_transaction|
			amount += incoming_transaction.funds
		end
		outcoming_transactions.each do |outcoming_transaction|
			amount -= outcoming_transaction.funds
		end
		amount
	end
	
	def send_funds(receiver_wallet, funds)
		if calculate_balance >= funds
			signature = OpenSSL::PKey::RSA.new(private_key, PEM_PASSWORD).sign(OpenSSL::Digest::SHA256.new, "#{public_key}#{receiver_wallet.public_key}#{funds}")
			Transaction.new(self, receiver_wallet, funds, signature)
		end
	end
	
	private 
	
	attr_accessor :initial_amount
	
end

class Block

	attr_accessor :time_stamp, :hash
	
	def initialize(prev_block, transaction)
		@prev_block = prev_block
		@transaction = transaction
		@time_stamp = Time.now.getutc
		@hash = calculate_hash
	end
	
	def is_block_valid
		if hash.eql? calculate_hash
			if prev_block
				prev_block.is_block_valid
			else
				true
			end
		else 
			false
		end
	end
	
	private
	
	attr_accessor :prev_block, :transaction
	
	def calculate_hash()
		hash = ""
		nonce = 0
		while not hash.start_with?("0")
			hash = Digest::SHA256.hexdigest "#{prev_block.hash}#{time_stamp}#{transaction.id}#{nonce}"
			nonce += 1
		end
	end
	
end

class Chain

	def initialize()
		@blocks = []
	end
	
	def add_block(transaction)
		if is_chain_valid and transaction.process
			block = Block.new(blocks.last, transaction)
			blocks.push(block)
		end
	end
	
	private
	
	attr_accessor :blocks
	
	def is_chain_valid
		if(blocks.length > 0)
			blocks.last.is_block_valid
		else 
			true
		end
	end
	
end
	
chain = Chain.new()

wallet_A = Wallet.new(50.0)
wallet_B = Wallet.new(0)

puts

puts("Wallet A balance: #{wallet_A.calculate_balance}")
puts("Wallet B balance: #{wallet_B.calculate_balance}")

puts

transaction_1 = wallet_A.send_funds(wallet_B, 10.0)

chain.add_block(transaction_1)

puts("Wallet A balance: #{wallet_A.calculate_balance}")
puts("Wallet B balance: #{wallet_B.calculate_balance}")

puts

transaction_2 = wallet_B.send_funds(wallet_A, 5.0)

chain.add_block(transaction_2)

puts("Wallet A balance: #{wallet_A.calculate_balance}")
puts("Wallet B balance: #{wallet_B.calculate_balance}")