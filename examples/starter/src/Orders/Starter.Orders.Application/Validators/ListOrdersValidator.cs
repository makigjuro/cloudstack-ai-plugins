using FluentValidation;
using Starter.Orders.Application.Errors;
using Starter.Orders.Application.Queries;

namespace Starter.Orders.Application.Validators;

public class ListOrdersValidator : AbstractValidator<ListOrdersQuery>
{
    public const int MaxPageSize = 100;

    public ListOrdersValidator()
    {
        RuleFor(x => x.TenantId)
            .NotEmpty()
            .WithErrorCode(OrderErrors.TenantIdRequiredCode)
            .WithMessage("A tenant is required.");

        RuleFor(x => x.PageNumber)
            .GreaterThanOrEqualTo(1)
            .WithErrorCode(OrderErrors.InvalidPageNumberCode)
            .WithMessage("Page number must be 1 or greater.");

        RuleFor(x => x.PageSize)
            .InclusiveBetween(1, MaxPageSize)
            .WithErrorCode(OrderErrors.InvalidPageSizeCode)
            .WithMessage($"Page size must be between 1 and {MaxPageSize}.");
    }
}
