class AnalysisService
  def self.summarize(scope, value: ->(record) { record.amount })
    records = scope.to_a
    total   = records.sum { |r| value.call(r) }.to_f

    by_category = records.group_by(&:category).map do |category, items|
      amount = items.sum { |r| value.call(r) }.to_f
      {
        category_id:    category&.id.to_s,
        category_name:  category&.name || "Uncategorized",
        category_color: category&.color,
        amount:         amount,
        percent:        total > 0 ? (amount / total * 100).round(1) : 0.0
      }
    end.sort_by { |c| -c[:amount] }

    { total: total, count: records.size, by_category: by_category }
  end
end
