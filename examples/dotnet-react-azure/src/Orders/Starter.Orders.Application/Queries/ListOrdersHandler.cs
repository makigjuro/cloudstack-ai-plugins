using FluentValidation;
using Starter.Domain.Repositories;
using Starter.Domain.ValueObjects;
using Starter.Orders.Application.Contracts;
using Starter.Orders.Application.Validators;
using Starter.Shared.Infrastructure.Results;

namespace Starter.Orders.Application.Queries;

public class ListOrdersHandler
{
    private readonly IOrderQueryRepository _queryRepository;
    private readonly IValidator<ListOrdersQuery> _validator;

    public ListOrdersHandler(IOrderQueryRepository queryRepository, IValidator<ListOrdersQuery> validator)
    {
        _queryRepository = queryRepository;
        _validator = validator;
    }

    public async Task<Result<OrderListResponse>> Handle(ListOrdersQuery query, CancellationToken cancellationToken)
    {
        var validation = await _validator.ValidateAsync(query, cancellationToken);
        if (!validation.IsValid)
            return Result.Failure<OrderListResponse>(validation.ToValidationError());

        var (items, totalCount) = await _queryRepository.ListAsync(
            new TenantId(query.TenantId), query.PageNumber, query.PageSize, cancellationToken);

        var response = new OrderListResponse(
            items.Select(order => order.ToResponse()).ToList(),
            totalCount,
            query.PageNumber,
            query.PageSize);

        return Result.Success(response);
    }
}
