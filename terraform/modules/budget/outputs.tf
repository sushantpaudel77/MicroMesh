output "budget_id" {
  description = "Budget ID"
  value       = aws_budgets_budget.monthly.id
}

output "budget_name" {
  description = "Budget name"
  value       = aws_budgets_budget.monthly.name
}

output "budget_amount" {
  description = "Budget amount"
  value       = aws_budgets_budget.monthly.limit_amount
}