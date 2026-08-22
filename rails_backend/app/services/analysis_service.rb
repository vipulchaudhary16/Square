class AnalysisService
  def self.summarize(scope, value: ->(record) { record.amount }, previous_scope: nil)
    records = scope.to_a
    total   = records.sum { |r| value.call(r) }.to_f

    previous_total = nil
    previous_by_category = nil
    if previous_scope
      previous_records = previous_scope.to_a
      previous_total = previous_records.sum { |r| value.call(r) }.to_f
      previous_by_category = previous_records.group_by(&:category).transform_values do |items|
        items.sum { |r| value.call(r) }.to_f
      end
    end

    by_category = records.group_by(&:category).map do |category, items|
      amount = items.sum { |r| value.call(r) }.to_f
      row = {
        category_id:    category&.id.to_s,
        category_name:  category&.name || "Uncategorized",
        category_color: category&.color,
        amount:         amount,
        percent:        total > 0 ? (amount / total * 100).round(1) : 0.0
      }
      if previous_by_category
        previous_amount = previous_by_category[category] || 0.0
        row[:delta_percent] = previous_amount.zero? ? nil : ((amount - previous_amount) / previous_amount * 100).round(1)
      end
      row
    end.sort_by { |c| -c[:amount] }

    result = { total: total, count: records.size, by_category: by_category }

    if previous_scope
      result[:delta_percent] = previous_total.zero? ? nil : ((total - previous_total) / previous_total * 100).round(1)
    end

    result
  end
end
