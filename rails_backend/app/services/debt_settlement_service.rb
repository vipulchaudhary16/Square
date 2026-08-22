class DebtSettlementService
  Debt = Struct.new(:from_id, :to_id, :amount)

  def self.compute(expenses, settlements = [])
    net = Hash.new(0.0)

    expenses.each do |exp|
      amount = exp.amount.to_f
      net[exp.payer_id] += amount

      splits = exp.expense_splits
      if splits.any?
        splits.each do |s|
          share = exp.split_type == "PERCENT" ? (amount * s.amount.to_f / 100.0) : s.amount.to_f
          net[s.user_id] -= share
        end
      else
        participants = exp.expense_participants
        if participants.any?
          share = amount / participants.size.to_f
          participants.each { |p| net[p.user_id] -= share }
        end
      end
    end

    settlements.each do |s|
      amount = s.amount.to_f
      net[s.user_id]    += amount
      net[s.to_user_id] -= amount
    end

    net.transform_values! { |v| (v * 100).round / 100.0 }

    debtors   = net.select { |_, v| v < -0.01 }.keys
    creditors = net.select { |_, v| v >  0.01 }.keys

    debts = []
    i = j = 0

    while i < debtors.size && j < creditors.size
      debtor_id   = debtors[i]
      creditor_id = creditors[j]

      debtor_bal   = -net[debtor_id]
      creditor_bal =  net[creditor_id]

      settle = [[debtor_bal, creditor_bal].min * 100].map { |v| v.round }.first / 100.0

      debts << Debt.new(debtor_id, creditor_id, settle) if settle > 0

      net[debtor_id]   += settle
      net[creditor_id] -= settle

      i += 1 if -net[debtor_id]   < 0.01
      j += 1 if  net[creditor_id] < 0.01
    end

    debts
  end
end
