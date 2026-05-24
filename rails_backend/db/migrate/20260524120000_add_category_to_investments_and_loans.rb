class AddCategoryToInvestmentsAndLoans < ActiveRecord::Migration[7.2]
  def change
    add_reference :investments, :category, foreign_key: true, null: true
    add_reference :loans,       :category, foreign_key: true, null: true
  end
end
