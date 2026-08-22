module Dashboard
  # Aggregates the totals, recent activity, and trend graph shown on the
  # dashboard home screen, for whichever models the host app configures via
  # Dashboard.expense_model / income_model / investment_model / loan_model.
  class Summary
    def initialize(user, include_trends: true)
      @user             = user
      @include_trends   = include_trends
      @expense_model    = Dashboard.expense_model
      @income_model     = Dashboard.income_model
      @investment_model = Dashboard.investment_model
      @loan_model       = Dashboard.loan_model
    end

    def as_json
      {
        total_expenses:  total_expenses,
        total_income:    total_income,
        total_invested:  total_invested,
        lent_amount:     lent_amount,
        borrowed_amount: borrowed_amount,
        recent_expenses: recent_expenses.map { |e| expense_json(e) },
        expense_graph:   @include_trends ? expense_graph : []
      }
    end

    private

    def user_expense_ids
      @user_expense_ids ||= @expense_model
        .joins("LEFT JOIN expense_participants ep ON ep.expense_id = expenses.id")
        .where("expenses.payer_id = :uid OR ep.user_id = :uid", uid: @user.id)
        .distinct
        .pluck(:id)
    end

    def total_expenses
      @expense_model.where(id: user_expense_ids).sum(:amount).to_f
    end

    def total_income
      @income_model.where(user: @user).sum(:amount).to_f
    end

    def total_invested
      @investment_model.where(user: @user).sum(:current_value).to_f
    end

    def lent_amount
      @loan_model.where(lender_user_id: @user.id, status: "PENDING").sum(:amount).to_f
    end

    def borrowed_amount
      @loan_model.where(borrower_user_id: @user.id, status: "PENDING").sum(:amount).to_f
    end

    def recent_expenses
      @expense_model
        .where(id: user_expense_ids)
        .includes(:payer, :group, :category, :expense_participants)
        .order(date: :desc)
        .limit(5)
    end

    def expense_json(e)
      {
        id:            e.id.to_s,
        description:   e.description,
        amount:        e.amount.to_f,
        category_id:   e.category_id.to_s,
        category_name: e.category&.name || "",
        date:          e.date.iso8601,
        payer_id:      e.payer_id.to_s,
        payer_name:    e.payer.display_name,
        group_id:      e.group_id&.to_s,
        group_name:    e.group&.name,
        participants:  e.expense_participants.map { |p| p.user_id.to_s },
        splits:        {}
      }
    end

    def expense_graph
      now        = Time.current
      start_curr = now.beginning_of_month
      end_curr   = start_curr.next_month
      start_last = start_curr.prev_month

      curr = @expense_model
        .where(id: user_expense_ids)
        .where(date: start_curr...end_curr)
        .group("EXTRACT(DAY FROM date)::int")
        .sum(:amount)

      last_month = @expense_model
        .where(id: user_expense_ids)
        .where(date: start_last...start_curr)
        .group("EXTRACT(DAY FROM date)::int")
        .sum(:amount)

      (1..end_curr.prev_day.day).map do |day|
        {
          day: day,
          current_month: day <= now.day ? (curr[day]&.to_f || 0.0) : nil,
          last_month: last_month[day]&.to_f || 0.0
        }
      end
    end
  end
end
