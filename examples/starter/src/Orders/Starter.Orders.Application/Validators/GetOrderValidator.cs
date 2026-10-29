using FluentValidation;
using Starter.Orders.Application.Errors;
using Starter.Orders.Application.Queries;

namespace Starter.Orders.Application.Validators;

public class GetOrderValidator : AbstractValidator<GetOrderQuery>
{
    public GetOrderValidator()
    {
        RuleFor(x => x.TenantId)
            .NotEmpty()
            .WithErrorCode(OrderErrors.TenantIdRequiredCode)
            .WithMessage("A tenant is required.");

        RuleFor(x => x.Id)
            .NotEmpty()
            .WithErrorCode(OrderErrors.OrderIdRequiredCode)
            .WithMessage("Order id is required.");
    }
}
