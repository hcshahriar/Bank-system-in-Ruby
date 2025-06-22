require 'json'
require 'securerandom'
require 'date'

class Bank
  def initialize
    @users_file = 'users.json'
    @accounts_file = 'accounts.json'
    @transactions_file = 'transactions.json'
    @current_user = nil
    load_data
  end

  def load_data
    @users = File.exist?(@users_file) ? JSON.parse(File.read(@users_file)) : []
    @accounts = File.exist?(@accounts_file) ? JSON.parse(File.read(@accounts_file)) : []
    @transactions = File.exist?(@transactions_file) ? JSON.parse(File.read(@transactions_file)) : []
  end

  def save_data
    File.write(@users_file, JSON.generate(@users))
    File.write(@accounts_file, JSON.generate(@accounts))
    File.write(@transactions_file, JSON.generate(@transactions))
  end

  def create_user(name, email, password)
    user = { id: SecureRandom.uuid, name: name, email: email, password: password, created_at: Time.now.to_s }
    @users << user
    save_data
    user
  end

  def authenticate(email, password)
    @current_user = @users.find { |u| u['email'] == email && u['password'] == password }
  end

  def create_account(user_id, type, balance = 0)
    account = { id: SecureRandom.uuid, user_id: user_id, type: type, balance: balance.to_f, active: true }
    @accounts << account
    save_data
    account
  end

  def deactivate_account(account_id)
    account = @accounts.find { |a| a['id'] == account_id }
    account['active'] = false if account
    save_data
  end

  def deposit(account_id, amount)
    account = @accounts.find { |a| a['id'] == account_id && a['active'] }
    return false unless account
    account['balance'] += amount.to_f
    log_transaction(account_id, 'deposit', amount)
    save_data
    true
  end

  def withdraw(account_id, amount)
    account = @accounts.find { |a| a['id'] == account_id && a['active'] }
    return false unless account && account['balance'] >= amount.to_f
    account['balance'] -= amount.to_f
    log_transaction(account_id, 'withdrawal', amount)
    save_data
    true
  end

  def transfer(source_id, target_id, amount)
    return false unless withdraw(source_id, amount) && deposit(target_id, amount)
    log_transaction(source_id, 'transfer_out', amount, target_id)
    log_transaction(target_id, 'transfer_in', amount, source_id)
    true
  end

  def log_transaction(account_id, type, amount, related_account_id = nil)
    transaction = {
      id: SecureRandom.uuid,
      account_id: account_id,
      type: type,
      amount: amount.to_f,
      related_account: related_account_id,
      timestamp: Time.now.to_s
    }
    @transactions << transaction
  end

  def get_user_accounts(user_id)
    @accounts.select { |a| a['user_id'] == user_id && a['active'] }
  end

  def get_account_transactions(account_id)
    @transactions.select { |t| t['account_id'] == account_id }
  end

  def start_cli
    loop do
      if @current_user
        puts "1. Create Account | 2. Deposit | 3. Withdraw | 4. Transfer | 5. View Transactions | 6. Logout"
        choice = gets.chomp.to_i
        case choice
        when 1
          puts "Account Type (checking/savings):"
          type = gets.chomp
          create_account(@current_user['id'], type)
        when 2
          puts "Account ID:"
          id = gets.chomp
          puts "Amount:"
          amount = gets.chomp.to_f
          deposit(id, amount)
        when 3
          puts "Account ID:"
          id = gets.chomp
          puts "Amount:"
          amount = gets.chomp.to_f
          withdraw(id, amount)
        when 4
          puts "Source Account ID:"
          src = gets.chomp
          puts "Target Account ID:"
          trg = gets.chomp
          puts "Amount:"
          amount = gets.chomp.to_f
          transfer(src, trg, amount)
        when 5
          puts "Account ID:"
          id = gets.chomp
          get_account_transactions(id).each { |t| puts "#{t['type']}: $#{t['amount']} at #{t['timestamp']}" }
        when 6
          @current_user = nil
        end
      else
        puts "1. Login | 2. Register | 3. Exit"
        choice = gets.chomp.to_i
        case choice
        when 1
          puts "Email:"
          email = gets.chomp
          puts "Password:"
          password = gets.chomp
          authenticate(email, password)
        when 2
          puts "Name:"
          name = gets.chomp
          puts "Email:"
          email = gets.chomp
          puts "Password:"
          password = gets.chomp
          create_user(name, email, password)
        when 3
          save_data
          break
        end
      end
    end
  end
end

bank = Bank.new
bank.start_cli
