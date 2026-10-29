using FluentValidation;
using Starter.Domain.Repositories;
using Starter.Domain.ValueObjects;
using Starter.Orders.Application.Contracts;
using Starter.Orders.Application.Errors;
using Starter.Orders.Application.Validators;
using Starter.Shared.Infrastructure.Results;

namespace Starter.Orders.Application.Queries;

public class GetOrderHandler
{
    private readonly IOrderQueryRepository _queryRepository;
    private readonly IValidator<GetOrderQuery> _validator;

    public GetOrderHandler(IOrderQueryRepository queryRepository, IValidator<GetOrderQuery> validator)
    {
        _queryRepository = queryRepository;
        _validator = validator;
    }

    public async Task<Result<OrderResponse>> Handle(GetOrderQuery query, CancellationToken cancellationToken)
    {
        var validation = await _validator.ValidateAsync(query, cancellationToken);
        if (!validation.IsValid)
            return Result.Failure<OrderResponse>(validation.ToValidationError());

        var order = await _queryRepository.GetByIdAsync(new OrderId(query.Id), cancellationToken);

        // Another tenant's order is reported as not found so its existence is not leaked.
        if (order is null || order.TenantId != new TenantId(query.TenantId))
            return Result.Failure<OrderResponse>(OrderErrors.NotFound(query.Id));

        return Result.Success(order.ToResponse());
    }
}
