class ExpenseSplitCalculator
  def self.calculate(amount, split_type, participant_ids, raw_splits = {})
    case split_type&.upcase
    when "EQUAL"
      raise ArgumentError, "No participants provided" if participant_ids.empty?
      share = (amount / participant_ids.size.to_f).round(2)
      participant_ids.each_with_object({}) { |uid, h| h[uid.to_s] = share }

    when "EXACT"
      total = raw_splits.values.sum.to_f
      unless (total - amount.to_f).abs < 0.01
        raise ArgumentError, "Split amounts (#{total}) do not match total (#{amount})"
      end
      raw_splits.slice(*participant_ids.map(&:to_s))

    when "PERCENT"
      total_pct = raw_splits.values.sum.to_f
      unless (total_pct - 100.0).abs < 0.1
        raise ArgumentError, "Split percentages (#{total_pct}) must equal 100"
      end
      raw_splits.each_with_object({}) do |(uid, pct), h|
        h[uid.to_s] = (amount.to_f * pct.to_f / 100.0).round(2) if participant_ids.map(&:to_s).include?(uid.to_s)
      end

    else
      return {} if participant_ids.empty?
      share = (amount.to_f / participant_ids.size.to_f).round(2)
      participant_ids.each_with_object({}) { |uid, h| h[uid.to_s] = share }
    end
  end
end
