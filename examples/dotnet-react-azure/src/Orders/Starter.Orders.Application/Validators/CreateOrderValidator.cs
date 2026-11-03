using FluentValidation;
using Starter.Domain.Entities;
using Starter.Orders.Application.Commands;
using Starter.Orders.Application.Errors;

namespace Starter.Orders.Application.Validators;

public class CreateOrderValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderValidator()
    {
        RuleFor(x => x.TenantId)
            .NotEmpty()
            .WithErrorCode(OrderErrors.TenantIdRequiredCode)
            .WithMessage("A tenant is required.");

        RuleFor(x => x.CustomerName)
            .Must(name => !string.IsNullOrWhiteSpace(name))
            .WithErrorCode(OrderErrors.CustomerNameRequiredCode)
            .WithMessage("Customer name is required.")
            .MaximumLength(Order.CustomerNameMaxLength)
            .WithErrorCode(OrderErrors.CustomerNameTooLongCode)
            .WithMessage($"Customer name must be at most {Order.CustomerNameMaxLength} characters.");

        RuleFor(x => x.TotalAmount)
            .GreaterThan(0)
            .WithErrorCode(OrderErrors.TotalAmountNotPositiveCode)
            .WithMessage("Total amount must be greater than zero.");
    }
}
