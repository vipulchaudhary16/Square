class InterestCalculatorService
  def initialize(loan)
    @loan = loan
  end

  def call
    outstanding = [(@loan.amount - @loan.loan_payments.sum(:amount)).to_f, 0.0].max
    return base_result(outstanding) if @loan.interest_mode == "none"

    daily_rate = normalize_rate
    days       = applicable_days

    interest = calculate_interest(outstanding, daily_rate, days)

    {
      outstanding:       outstanding.round(2),
      accrued_interest:  interest.round(2),
      total_due:         (outstanding + interest).round(2),
      daily_rate:        daily_rate.round(8),
      interest_timeline: build_timeline(outstanding, daily_rate, days)
    }
  end

  private

  def base_result(outstanding)
    { outstanding: outstanding.round(2), accrued_interest: 0.0,
      total_due: outstanding.round(2), daily_rate: 0.0, interest_timeline: [] }
  end

  def normalize_rate
    rate = (@loan.interest_rate || 0).to_f
    case @loan.interest_period
    when "monthly" then rate / 30
    when "annual"  then rate / 365
    else rate
    end
  end

  def applicable_days
    today = Date.today
    if @loan.interest_mode == "from_start"
      (today - @loan.date.to_date).to_i
    else
      [(today - @loan.due_date.to_date).to_i, 0].max
    end
  end

  def calculate_interest(outstanding, daily_rate, days)
    return 0.0 if days <= 0 || daily_rate <= 0
    if @loan.interest_basis == "total"
      outstanding * ((1 + daily_rate)**days - 1)
    else
      outstanding * daily_rate * days
    end
  end

  def build_timeline(outstanding, daily_rate, days)
    return [] if days <= 0 || daily_rate <= 0

    start_date = if @loan.interest_mode == "from_start"
      @loan.date.to_date + 1
    else
      @loan.due_date.to_date + 1
    end

    cumulative = 0.0
    (0...days).map do |i|
      daily = if @loan.interest_basis == "total"
        outstanding * daily_rate * (1 + daily_rate)**i
      else
        outstanding * daily_rate
      end
      cumulative += daily
      {
        date:           (start_date + i).iso8601,
        daily_interest: daily.round(2),
        cumulative:     cumulative.round(2)
      }
    end
  end
end
