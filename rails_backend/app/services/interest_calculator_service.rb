class InterestCalculatorService
  def initialize(loan)
    @loan = loan
  end

  def call
    outstanding = [(@loan.amount - @loan.loan_payments.sum(:amount)).to_f, 0.0].max
    return base_result(outstanding) if @loan.interest_mode == "none"

    case @loan.interest_period
    when "monthly" then calculate_periodic(outstanding, :monthly)
    when "annual"  then calculate_periodic(outstanding, :annual)
    else                calculate_daily(outstanding)
    end
  end

  private

  def base_result(outstanding)
    { outstanding: outstanding.round(2), accrued_interest: 0.0,
      total_due: outstanding.round(2), daily_rate: 0.0, interest_timeline: [] }
  end

  # ── Daily ────────────────────────────────────────────────────────────────────

  def calculate_daily(outstanding)
    rate = (@loan.interest_rate || 0).to_f / 100.0
    days = applicable_days

    interest = compound?  ? outstanding * ((1 + rate)**days - 1)
                          : outstanding * rate * days
    interest = [interest, 0.0].max

    {
      outstanding:       outstanding.round(2),
      accrued_interest:  interest.round(2),
      total_due:         (outstanding + interest).round(2),
      daily_rate:        rate.round(8),
      interest_timeline: build_daily_timeline(outstanding, rate, days)
    }
  end

  def build_daily_timeline(outstanding, rate, days)
    return [] if days <= 0 || rate <= 0

    cumulative = 0.0
    (0...days).map do |i|
      daily = compound? ? outstanding * rate * (1 + rate)**i
                        : outstanding * rate
      cumulative += daily
      { date: (interest_start_date + i).iso8601,
        daily_interest: daily.round(2),
        cumulative:     cumulative.round(2) }
    end
  end

  # ── Monthly / Annual (flat-rate per period) ──────────────────────────────────

  def calculate_periodic(outstanding, unit)
    rate      = (@loan.interest_rate || 0).to_f / 100.0
    start     = interest_start_date
    today     = Date.today
    timeline  = []
    cumulative = 0.0
    cursor    = start

    while cursor < today
      period_end, label = next_period_boundary(cursor, unit)
      period_end = [period_end, today].min

      fraction = partial_fraction(cursor, period_end, unit)

      period_interest = compound? ? outstanding * ((1 + rate)**fraction - 1)
                                  : outstanding * rate * fraction
      cumulative += period_interest
      timeline << { date: label, period_interest: period_interest.round(2),
                    cumulative: cumulative.round(2) }

      cursor = period_end
    end

    total = cumulative
    { outstanding:       outstanding.round(2),
      accrued_interest:  total.round(2),
      total_due:         (outstanding + total).round(2),
      daily_rate:        0.0,
      interest_timeline: timeline }
  end

  # Returns [exclusive_end_date, human_label] for the period starting at `date`.
  def next_period_boundary(date, unit)
    if unit == :monthly
      [(date >> 1), date.strftime("%B %Y")]
    else
      [Date.new(date.year + 1, date.month, date.day), date.year.to_s]
    end
  end

  # Fraction of the period covered by [start, end).
  # A complete period = 1.0; partial uses actual days / days-in-period.
  def partial_fraction(period_start, period_end, unit)
    period_length = if unit == :monthly
      (period_start >> 1) - period_start   # exact days in this calendar month
    else
      (Date.new(period_start.year + 1, period_start.month, period_start.day) - period_start).to_i
    end
    (period_end - period_start).to_f / period_length
  end

  # ── Shared helpers ────────────────────────────────────────────────────────────

  def applicable_days
    today = Date.today
    if @loan.interest_mode == "from_start"
      (today - @loan.date.to_date).to_i
    else
      [(today - @loan.due_date.to_date).to_i, 0].max
    end
  end

  def interest_start_date
    if @loan.interest_mode == "from_start"
      @loan.date.to_date + 1
    else
      @loan.due_date.to_date + 1
    end
  end

  def compound?
    @loan.interest_basis == "total"
  end
end
